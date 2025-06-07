with Coroutines;
pragma Elaborate_All (Coroutines);

generic
   with procedure Root_Function;
package scheduler is
   procedure Spawn_RT;

private
   Local_Worker_Queue_Size_Total : constant Natural := 256;
   Local_Worker_Queue_Size_Half  : constant Natural :=
     Local_Worker_Queue_Size_Total / 2;
   type Local_Worker_Queue_Idx is
     new Natural range 1 .. Local_Worker_Queue_Size_Total;
   Local_Worker_Queue_Idx_Half   : constant Local_Worker_Queue_Idx :=
     Local_Worker_Queue_Idx (Local_Worker_Queue_Size_Half);
   Global_Task_Info_Size_Total   : constant Natural := 2**16; -- 65536
   type Global_Task_Info_Idx is
     new Natural range 1 .. Global_Task_Info_Size_Total;

   Worker_Count : constant Natural := 2;

   type Task_Info is record
      C : Coroutines.Coroutine;
   end record;

   type Local_Worker_Task_Info_Array is
     array (Local_Worker_Queue_Idx) of Task_Info;
   type Global_Task_Info_Array is array (Global_Task_Info_Idx) of Task_Info;

   protected Global_Task_Queue is
      procedure Push (TI : Local_Worker_Task_Info_Array);
      -- Pushes half of the local array into the global queue
      procedure Pull
        (TI : in out Local_Worker_Task_Info_Array; Count : out Natural);
      -- Pulls tasks from the global queue into the local array, enough to fill half of it
   private
      Global_TI_Array : Global_Task_Info_Array :=
        (others => (C => Coroutines.Null_Coroutine));
      First, Last     : Natural := 0;
   end Global_Task_Queue;

   protected type Worker_Task_Queue is
      procedure Push (TI : Task_Info);
      entry Pop (TI : out Task_Info);
      procedure Steal
        (TI : in out Local_Worker_Task_Info_Array; Count : out Natural);
   private
      Q    : Local_Worker_Task_Info_Array;
      Size : Natural := 0;
   end Worker_Task_Queue;

   type Worker_Idx is new Natural range 1 .. Worker_Count;
   Local_Work_Task_Queues : array (Worker_Idx) of Worker_Task_Queue;

   task type Worker_Task is
      entry Start (Idx : Worker_Idx);
   end Worker_Task;

   type Worker_Task_Root_Delegate is new Coroutines.Delegate with record
      W_Idx : Worker_Idx;
      --  The index of the worker task
   end record;
   overriding
   procedure Run (D : in out Worker_Task_Root_Delegate);

   type Worker_Root_Delegate is new Coroutines.Delegate with null record;
   type Worker_Root_Delegate_Access is access all Worker_Root_Delegate;

   overriding
   procedure Run (D : in out Worker_Root_Delegate);
end scheduler;
