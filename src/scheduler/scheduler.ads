with Ada.Calendar;

package scheduler is
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

private
   Null_Future : constant Future_Access := null;

   Local_Worker_Queue_Size_Total : constant Natural := 256;
   Local_Worker_Queue_Size_Half  : constant Natural :=
     Local_Worker_Queue_Size_Total / 2;
   type Local_Worker_Queue_Idx is
     new Natural range 1 .. Local_Worker_Queue_Size_Total;
   Local_Worker_Queue_Idx_Half   : constant Local_Worker_Queue_Idx :=
     Local_Worker_Queue_Idx (Local_Worker_Queue_Size_Half);
   Global_Task_Info_Size_Total   : constant Natural := 2**18; -- 262144
   type Global_Task_Info_Idx is
     new Natural range 1 .. Global_Task_Info_Size_Total;

   Worker_Count : constant Natural := 4;

   type Time_Access is access all Ada.Calendar.Time;

   type Task_State is (Ready, Running, Cancelled, Blocked_Time, Blocked_IO, Completed);

   type Task_Info is record
      Fut          : Future_Access;
      State        : Task_State := Ready;
      Blocked_Time : Time_Access := null;
   end record;

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
      procedure Process_QB;
      -- Pulls tasks from the global queue into the local array, enough to fill half of it
   private
      Global_TI_Array : Global_Task_Info_Array :=
        (others => (Fut => Null_Future, State => Ready, Blocked_Time => null));
      First, Last     : Natural := 0;

      Global_TI_B_Array : Global_Task_Info_Array :=
        (others => (Fut => Null_Future, State => Ready, Blocked_Time => null));
      Size_QB  : Natural := 0;
   end Global_Task_Queue;

   protected type Worker_Task_Queue is
      function Has_Work_Left return Boolean;

      procedure Push (TI : Task_Info);
      procedure Push_QB (TI : Task_Info);
      procedure Process_QB;

      procedure Pop (TI : out Task_Info);
      procedure Steal
        (TI : in out Local_Worker_Task_Info_Array; Count : out Natural);

      procedure Print_States;
   private
      Q    : Local_Worker_Task_Info_Array;
      Size : Natural := 0;
      Clk_Current : Local_Worker_Queue_Idx;
      Clk_Idx : Local_Worker_Queue_Idx;
      QB   : Local_Worker_Task_Info_Array; -- Buffer for blocked tasks
      Size_QB : Natural := 0;
   end Worker_Task_Queue;

   type Worker_Idx is new Natural range 1 .. Worker_Count;
   Local_Work_Task_Queues : array (Worker_Idx) of Worker_Task_Queue;

   task type Worker_Task is
      entry Start (Idx : Worker_Idx);
   end Worker_Task;

   type Sched_Cx is record
      W_Idx      : Worker_Idx;
      Sched_Time : Time_Access;
      Cancelled  : Boolean := False;
   end record;
end scheduler;
