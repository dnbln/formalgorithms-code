with Ada.Text_IO;

package body scheduler is
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

   procedure Run_Main_Root_Delegate (W_Idx : Worker_Idx) is
      TI       : Task_Info;
      Finished : Boolean;
   begin
      Ada.Text_IO.Put_Line
        ("Worker Task Root Delegate started for worker "
         & Worker_Idx'Image (W_Idx));
      loop
         Local_Work_Task_Queues (W_Idx).Pop (TI);
         TI.Fut.Poll (Finished => Finished);
         if not Finished then
            Local_Work_Task_Queues (W_Idx).Push (TI);
         end if;
      end loop;
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

   procedure Spawn_RT (Root : Future_Access) is
      Workers   : array (Worker_Idx) of Worker_Task;
      TI        : Task_Info;
   begin
      for I in Workers'Range loop
         Workers (I).Start (I);
      end loop;

      Local_Work_Task_Queues (Worker_Idx'First).Push
        (TI => (Fut => Root));

      -- Wait for all workers to complete
      loop
         null;
      end loop;


      --  Workers(1).Start(f);
   end Spawn_RT;
end scheduler;
