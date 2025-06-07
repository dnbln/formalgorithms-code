package scheduler is
   type Future is abstract tagged limited null record;
   procedure Poll (F : in out Future; Finished : out Boolean) is abstract;

   type Future_Access is access all Future'Class;
   procedure Spawn_RT(Root: Future_Access);

private
   Null_Future : constant Future_Access := null;

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
      Fut : Future_Access;
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
        (others => (Fut => Null_Future));
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
end scheduler;
