with Ada.Text_IO;
with PCL;
pragma Elaborate_All (PCL);

package body scheduler is
   pragma Linker_Options ("-L/usr/local/lib");

   protected body Global_Task_Queue is
      procedure Push (TI : Local_Worker_Task_Info_Array) is
         Count : Natural := 0;
         P     : Natural := 0;
      begin
         if P = First then
            raise Constraint_Error
              with "Global Task Queue is full, cannot push more tasks";
         end if;
         for I in Local_Worker_Queue_Idx'First .. Local_Worker_Queue_Idx_Half
         loop
            P := ((Last + Natural (I)) mod Global_Task_Info_Size_Total) + 1;
            Global_TI_Array (Global_Task_Info_Idx (P)) := TI (I);
         end loop;

         Last := Last + Local_Worker_Queue_Size_Half;
      end Push;

      procedure Pull
        (TI : in out Local_Worker_Task_Info_Array; Count : out Natural)
      is
         Size : constant Natural := Last - First;
      begin
         Count := 0;
         if Size = 0 then
            return;
         end if;
         for I
           in Global_Task_Info_Idx'First
              .. Global_Task_Info_Idx (Local_Worker_Queue_Idx_Half)
         loop
            if Natural (I) > Size then
               exit;
            end if;

            TI (Local_Worker_Queue_Idx (Natural (TI'First) + Count)) :=
              Global_TI_Array (I);
            Count := Count + 1;
         end loop;

         First := First + Count;
      end Pull;
   end Global_Task_Queue;

   protected body Worker_Task_Queue is
      procedure Push (TI : Task_Info) is
      begin
         if Size = Local_Worker_Queue_Size_Total then
            Global_Task_Queue.Push (Q);
            for I
              in Local_Worker_Queue_Idx'First .. Local_Worker_Queue_Idx_Half
            loop
               Q (I) := Q (Local_Worker_Queue_Idx_Half + I);
            end loop;
            Size := Size / 2;
         end if;

         Size := Size + 1;
         Q (Local_Worker_Queue_Idx (Size)) := TI;

         Ada.Text_IO.Put_Line
           ("Worker Task Queue: Pushed task, new size is "
            & Natural'Image (Size));
      end Push;
      entry Pop (TI : out Task_Info) when Size > 0 is
      begin
         if Size > 0 then
            TI := Q (Local_Worker_Queue_Idx (Size));
            Size := Size - 1;
            Ada.Text_IO.Put_Line
              ("Worker Task Queue: Popped task, new size is "
               & Natural'Image (Size));
         else
            raise Constraint_Error with "Worker Task Queue is empty";
         end if;
      end Pop;
      procedure Steal
        (TI : in out Local_Worker_Task_Info_Array; Count : out Natural) is
      begin
         Count := 0;
         if Size = 0 then
            return;
         end if;
         for I
           in Local_Worker_Queue_Idx'First .. Local_Worker_Queue_Idx (Size / 2)
         loop
            TI (Local_Worker_Queue_Idx (Natural (TI'First) + Count)) := Q (I);
            Count := Count + 1;
         end loop;

         if Count > 0 then
            -- Shift remaining tasks in the queue
            for I
              in Local_Worker_Queue_Idx'First
                 + Local_Worker_Queue_Idx (Count)
                 .. Local_Worker_Queue_Idx (Size)
            loop
               Q (I - Local_Worker_Queue_Idx (Count)) := Q (I);
            end loop;
            Size := Size - Count;
         end if;
      end Steal;
   end Worker_Task_Queue;

   overriding
   procedure Run (D : in out Worker_Task_Root_Delegate) is
      TI    : Task_Info;
      W_Idx : constant Worker_Idx := D.W_Idx;
   begin
      Ada.Text_IO.Put_Line
        ("Worker Task Root Delegate started for worker "
         & Worker_Idx'Image (W_Idx));
      loop
         Local_Work_Task_Queues (W_Idx).Pop (TI);
         if not TI.C.Alive then
            TI.C.Spawn;
         end if;
         TI.C.Switch;
         if TI.C.Alive then
            Local_Work_Task_Queues (W_Idx).Push (TI);
         end if;
      end loop;
   end Run;

   procedure Run_Main_Root_Delegate (W_Idx : Worker_Idx) is
      Init : constant Integer := PCL.Thread_Init;
      C_D  : access Worker_Task_Root_Delegate;
      C_R  : Coroutines.Coroutine;
   begin
      if Init /= 0 then
         Ada.Text_IO.Put_Line
           ("Thread_Init failed with code " & Integer'Image (Init));
         return;
      end if;
      Ada.Text_IO.Put_Line ("Thread_Init succeeded");
      C_D := new Worker_Task_Root_Delegate'(W_Idx => W_Idx);
      C_R := Coroutines.Create (Coroutines.Delegate_Access (C_D));
      C_R.Spawn (Stack_Size => 8192);
      Ada.Text_IO.Put_Line
        ("[RUN] Main Root Delegate started for worker "
         & Worker_Idx'Image (W_Idx));
      C_R.Switch;

      PCL.Thread_Cleanup;
   end Run_Main_Root_Delegate;

   task body Worker_Task is
      W_Idx : Worker_Idx;
   begin
      Ada.Text_IO.Put_Line
        ("Worker Task started, waiting for Start entry call");
      accept Start (Idx : Worker_Idx) do
         W_Idx := Idx;
      end Start;
      Ada.Text_IO.Put_Line
        ("Worker Task " & Worker_Idx'Image (W_Idx) & " started");

      Run_Main_Root_Delegate (W_Idx);
      Ada.Text_IO.Put_Line
        ("Worker Task " & Worker_Idx'Image (W_Idx) & " finished");
   end Worker_Task;

   overriding
   procedure Run (D : in out Worker_Root_Delegate) is
   begin
      Root_Function;
   end Run;

   procedure Spawn_RT is
      Init      : constant Integer := PCL.Thread_Init;
      Workers   : array (Worker_Idx) of Worker_Task;
      TI        : Task_Info;
      Delg      : Worker_Root_Delegate_Access := new Worker_Root_Delegate;
      DelAccess : Coroutines.Delegate_Access;
      Coro      : Coroutines.Coroutine;
   begin
      if Init /= 0 then
         Ada.Text_IO.Put_Line
           ("Thread_Init failed with code " & Integer'Image (Init));
         return;
      end if;
      --  Workers(1).Start(f);

      Ada.Text_IO.Put_Line ("Thread_Init succeeded, pushing initial task");

      DelAccess := Coroutines.Delegate_Access (Delg);
      Delg := null;
      Ada.Text_IO.Put_Line ("[RUN] Created delegate for root function");
      Coro := Coroutines.Create (DelAccess);
      Ada.Text_IO.Put_Line ("[RUN] Created Coroutine for root delegate");
      TI := (C => Coro);
      Local_Work_Task_Queues (Worker_Idx (1)).Push (TI);

      Ada.Text_IO.Put_Line ("[RUN] Pushed initial task to worker 1");

      for I in Workers'Range loop
         Workers (I).Start (I);
      end loop;

      -- Wait for all workers to complete
      loop
         null;
      end loop;

      PCL.Thread_Cleanup;
   end Spawn_RT;
end scheduler;
