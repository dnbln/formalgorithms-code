with Ada.Text_IO;

package body scheduler is
   protected body Global_Task_Queue is
      function Has_Work_Left return Boolean
      is (First < Last);

      procedure Push (TI : Local_Worker_Task_Info_Array) is
         Count : Natural := 0;
         P     : Natural :=
           ((Last + Natural (1)) mod Global_Task_Info_Size_Total) + 1;
      begin
         --  if P = First then
         --     raise Constraint_Error
         --       with "Global Task Queue is full, cannot push more tasks";
         --  end if;
         for I in Local_Worker_Queue_Idx'First .. Local_Worker_Queue_Idx_Half
         loop
            P := ((Last + Natural (I)) mod Global_Task_Info_Size_Total) + 1;
            Global_TI_Array (Global_Task_Info_Idx (P)) := TI (I);
         end loop;

         Last := Last + Local_Worker_Queue_Size_Half;

         --  Ada.Text_IO.Put_Line
         --    ("Global Task Queue: Pushed "
         --     & Natural'Image (Local_Worker_Queue_Size_Half)
         --     & " tasks, new Last index: "
         --     & Natural'Image (Last));
      end Push;

      entry Pull
        (TI : in out Local_Worker_Task_Info_Array; Count : out Natural)
        when First < Last

      is
         Size : constant Natural := Last - First;
      begin
         Count := 0;
         --  Ada.Text_IO.Put_Line
         --    ("Global Task Queue: Pulling tasks, current Size: "
         --     & Natural'Image (Size)
         --     & ", First index: "
         --     & Natural'Image (First)
         --     & ", Last: "
         --     & Natural'Image (Last));
         if Size = 0 then
            return;
         end if;
         for I in Local_Worker_Queue_Idx'First .. Local_Worker_Queue_Idx_Half
         loop
            TI (I) :=
              Global_TI_Array (Global_Task_Info_Idx (First + Natural (I)));
            Count := Count + 1;
         end loop;

         First := First + Local_Worker_Queue_Size_Half;
         --  Ada.Text_IO.Put_Line
         --    ("Global Task Queue: Pulled "
         --     & Natural'Image (Count)
         --     & " tasks, new First index: "
         --     & Natural'Image (First));
      end Pull;
   end Global_Task_Queue;

   protected body Worker_Task_Queue is
      function Has_Work_Left return Boolean
      is (Size > 0);
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

      end Push;
      procedure Pop (TI : out Task_Info) is
      begin
         if Size > 0 then
            TI := Q (Local_Worker_Queue_Idx (Size));
            Size := Size - 1;
         else
            Global_Task_Queue.Pull (TI => Q, Count => Size);
            TI := Q (Local_Worker_Queue_Idx (Size));
            Size := Size - 1;
            --  Ada.Text_IO.Put_Line
            --    ("Worker Task Queue: Pop from global queue, new Size: "
            --     & Natural'Image (Size));
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

   type Busy_States_Array is array (Worker_Idx) of Boolean;

   protected Workers_Busy is
      function Any_Busy return Boolean;
      procedure Set_Busy (W_Idx : Worker_Idx; Busy : Boolean);
   private
      Busy_States : Busy_States_Array := (others => False);
   end Workers_Busy;

   protected body Workers_Busy is
      function Any_Busy return Boolean is
      begin
         for I in Worker_Idx'Range loop
            if Busy_States (I) then
               return True;
            end if;
         end loop;
         return False;
      end Any_Busy;

      procedure Set_Busy (W_Idx : Worker_Idx; Busy : Boolean) is
      begin
         Busy_States (W_Idx) := Busy;
      end Set_Busy;
   end Workers_Busy;

   procedure Run_Main_Root_Delegate (W_Idx : Worker_Idx) is
      TI       : Task_Info;
      Finished : Boolean;
      Sch_Cx   : constant Sched_Cx_Access := new Sched_Cx'(W_Idx => W_Idx);
   begin
      loop
         --  Ada.Text_IO.Put_Line
         --    ("Worker Task " & Worker_Idx'Image (W_Idx) & " waiting for task");
         Local_Work_Task_Queues (W_Idx).Pop (TI);
         --  Ada.Text_IO.Put_Line
         --    ("Worker Task " & Worker_Idx'Image (W_Idx) & " processing task");
         Workers_Busy.Set_Busy (W_Idx, True);
         TI.Fut.Poll (Sched_Cx => Sch_Cx, Finished => Finished);
         Workers_Busy.Set_Busy (W_Idx, False);
         if not Finished then
            Local_Work_Task_Queues (W_Idx).Push (TI);
         end if;
      end loop;
   end Run_Main_Root_Delegate;

   task body Worker_Task is
      W_Idx : Worker_Idx;
   begin
      accept Start (Idx : Worker_Idx) do
         W_Idx := Idx;
      end Start;
      --  Ada.Text_IO.Put_Line
      --    ("Worker Task " & Worker_Idx'Image (W_Idx) & " started");

      Run_Main_Root_Delegate (W_Idx);
      --  Ada.Text_IO.Put_Line
      --    ("Worker Task " & Worker_Idx'Image (W_Idx) & " finished");
   end Worker_Task;

   procedure Spawn_RT (Root : Future_Access) is
      Workers   : array (Worker_Idx) of Worker_Task;
      TI        : Task_Info;
      Work_Left : Boolean := True;
   begin
      Local_Work_Task_Queues (Worker_Idx'First).Push (TI => (Fut => Root));

      for I in Workers'Range loop
         Workers (I).Start (I);
      end loop;

      -- Wait for all workers to complete
      loop
         Work_Left := False;
         for I in Workers'Range loop
            if Local_Work_Task_Queues (I).Has_Work_Left then
               Work_Left := True;
               exit;
            end if;
         end loop;

         if not Work_Left
           and then not (Workers_Busy.Any_Busy)
           and then not Global_Task_Queue.Has_Work_Left
         then
            exit;
         end if;

         delay 0.01; -- Yield to allow other tasks to run
         --  Ada.Text_IO.Put_Line
         --    ("Waiting for workers to finish, work left: "
         --     & Boolean'Image (Work_Left));
      end loop;

   --  Workers(1).Start(f);
   end Spawn_RT;

   procedure Spawn (Sched_Cx : Sched_Cx_Access; F : Future_Access) is
      TI : Task_Info;
   begin
      if Sched_Cx = null then
         raise Constraint_Error with "Scheduler context cannot be null";
      end if;
      if F = null then
         raise Constraint_Error with "Future cannot be null";
      end if;
      TI.Fut := F;
      Local_Work_Task_Queues (Sched_Cx.W_Idx).Push (TI);
   end Spawn;
end scheduler;
