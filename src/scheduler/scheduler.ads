with Ada.Calendar;
with Interfaces;
with Interfaces.C;
with sys_event_h;

package Scheduler is
   type Task_Id is private;

   type Sched_Cx is limited private;
   type Sched_Cx_Access is access all Sched_Cx;

   type Future is abstract tagged limited null record;
   procedure Poll
     (F : in out Future; Sched_Cx : Sched_Cx_Access; Finished : out Boolean)
   is abstract;

   type Future_Access is access all Future'Class;
   procedure Spawn_RT (Root : Future_Access);

   procedure Spawn (Sched_Cx : Sched_Cx_Access; F : Future_Access);

   procedure Wake_In_Future
     (Sched_Cx : Sched_Cx_Access;
      Time     : Ada.Calendar.Time := Ada.Calendar.Clock);

   procedure Cancel (Sched_Cx : Sched_Cx_Access);

   --  procedure Wake_On_IO
   --    (Sched_Cx : Sched_Cx_Access;
   --     File     : Ada.Streams.Root_Stream_Type'Class);

   type Bytes is array (Positive range <>) of Interfaces.C.unsigned_char;

private
   Null_Future : constant Future_Access := null;
   type Poll_Result is new sys_event_h.kevent; -- KEvent structure for polling
   type Poll_Result_Buffer is array (1 .. 1024) of Poll_Result
   with Convention => C;
   type Poll_Results is record
      Count  : Integer; -- Number of events returned
      Events : Poll_Result_Buffer; -- Array of events
   end record;

   Local_Worker_Queue_Size_Total : constant Natural := 256;
   Local_Worker_Queue_Size_Half  : constant Natural :=
     Local_Worker_Queue_Size_Total / 2;
   type Local_Worker_Queue_Idx is
     new Natural range 1 .. Local_Worker_Queue_Size_Total;
   Local_Worker_Queue_Idx_Half   : constant Local_Worker_Queue_Idx :=
     Local_Worker_Queue_Idx (Local_Worker_Queue_Size_Half);
   Global_Task_Info_Size_Total   : constant Natural := 2**20; -- 1M
   type Global_Task_Info_Idx is
     new Natural range 1 .. Global_Task_Info_Size_Total;

   Worker_Count : constant Natural := 8;

   type Time_Access is access all Ada.Calendar.Time;

   type Task_State is
     (Ready, Running, Cancelled, Blocked_Time, Blocked_IO, Completed);

   type Task_Id is new Natural;

   protected Task_Id_Generator is
      procedure Get_Next (Id : out Task_Id);
      -- Returns the next available Task_Id
   private
      Current_Id : Task_Id := 0;
   end Task_Id_Generator;

   function Get_Next_Task_Id return Task_Id;

   type Blocked_IO_Type is (Read, Write);

   type Blocked_IO_Info is record
      FD           : Interfaces.C.int; -- File descriptor for the blocked IO
      Blocked_Type : Blocked_IO_Type;
   end record;

   type Blocked_IO_Info_Access is access all Blocked_IO_Info;
   type Task_Info is record
      Fut          : Future_Access;
      T_Id         : Task_Id;
      State        : Task_State := Ready;
      Blocked_Time : Time_Access := null;
      Blocked_IO   : Blocked_IO_Info_Access := null;
   end record;

   type IO_Blocked_Queue is record
      KQueue : Interfaces.C.int; -- KQueue file descriptor
   end record;

   type IO_Blocked_Queue_Access is access all IO_Blocked_Queue;

   function Create_IO_Blocked_Queue return IO_Blocked_Queue_Access;

   type Local_Worker_Task_Info_Array is
     array (Local_Worker_Queue_Idx) of Task_Info;
   type Global_Task_Info_Array is array (Global_Task_Info_Idx) of Task_Info;

   protected Global_Task_Queue is
      function Has_Work_Left return Boolean;

      procedure Push (TI : Local_Worker_Task_Info_Array);
      -- Pushes half of the local array into the global queue
      --  entry Pull
      --    (TI : in out Local_Worker_Task_Info_Array; Count : out Natural);

      procedure Try_Pull
        (TI : in out Local_Worker_Task_Info_Array; Count : out Natural);

      procedure Push_QB (TI : Local_Worker_Task_Info_Array);
      procedure Process_QB (Poll_R : Poll_Results);
      -- Pulls tasks from the global queue into the local array, enough to fill half of it
   private
      Global_TI_Array : Global_Task_Info_Array :=
        (others =>
           (Fut          => Null_Future,
            State        => Ready,
            Blocked_Time => null,
            Blocked_IO   => null,
            T_Id         => 0));
      First, Last     : Natural := 0;

      Global_TI_B_Array : Global_Task_Info_Array :=
        (others =>
           (Fut          => Null_Future,
            State        => Ready,
            Blocked_Time => null,
            Blocked_IO   => null,
            T_Id         => 0));
      Size_QB           : Natural := 0;

      IO_Q : IO_Blocked_Queue_Access := null;
   end Global_Task_Queue;

   protected type Worker_Task_Queue is
      function Has_Work_Left return Boolean;

      procedure Push (TI : Task_Info);
      procedure Push_QB (TI : Task_Info);
      procedure Process_QB (Poll_R : Poll_Results);

      procedure Pop (TI : out Task_Info; Poll_R : Poll_Results);
      procedure Steal
        (TI : in out Local_Worker_Task_Info_Array; Count : out Natural);

      procedure Print_States;
   private
      Q           : Local_Worker_Task_Info_Array;
      Size        : Natural := 0;
      Clk_Current : Local_Worker_Queue_Idx;
      Clk_Idx     : Local_Worker_Queue_Idx;
      QB          : Local_Worker_Task_Info_Array; -- Buffer for blocked tasks
      Size_QB     : Natural := 0;

      IO_Q : IO_Blocked_Queue_Access := null;
   end Worker_Task_Queue;

   type Worker_Idx is new Natural range 1 .. Worker_Count;
   Local_Work_Task_Queues : array (Worker_Idx) of Worker_Task_Queue;

   task type Worker_Task is
      entry Start (Idx : Worker_Idx);
   end Worker_Task;

   type Sched_Cx is record
      W_Idx      : Worker_Idx;
      Sched_Time : Time_Access;
      Sched_IO   : Blocked_IO_Info_Access;
      Cancelled  : Boolean := False;
   end record;

   type Udata_Info is record
      T_Id : Task_Id;                    -- Task identifier
   end record;

   type Udata_Info_Access is access all Udata_Info;

   procedure Add_Read_To_IO_Blocked_Queue
     (KQ     : IO_Blocked_Queue_Access;
      FD     : Interfaces.C.int;
      T_Info : Udata_Info_Access);
   procedure Add_Write_To_IO_Blocked_Queue
     (KQ     : IO_Blocked_Queue_Access;
      FD     : Interfaces.C.int;
      T_Info : Udata_Info_Access);
   procedure Remove_Read_From_IO_Blocked_Queue
     (KQ : IO_Blocked_Queue_Access; FD : Interfaces.C.int);
   procedure Remove_Write_From_IO_Blocked_Queue
     (KQ : IO_Blocked_Queue_Access; FD : Interfaces.C.int);
   function Poll_IO_Blocked_Queue
     (KQ : IO_Blocked_Queue_Access) return Poll_Results;

   procedure Wake_On_IO_Read
     (Sched_Cx : Scheduler.Sched_Cx_Access; File : Interfaces.C.int);

   procedure Wake_On_IO_Write
     (Sched_Cx : Scheduler.Sched_Cx_Access; File : Interfaces.C.int);
end Scheduler;
