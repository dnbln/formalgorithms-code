with Ada.Calendar; use Ada.Calendar;
with Ada.Text_IO;

package body scheduler is
   function Time_Image (T : Ada.Calendar.Time) return String is
      Year, Month, Day     : Integer;
      D                    : Ada.Calendar.Day_Duration;
      DI                   : Integer;
      Hour, Minute, Second : Integer;
   begin
      Ada.Calendar.Split (T, Year, Month, Day, D);
      DI := Integer (D);
      Second := DI mod 60;
      DI := DI / 60;
      Minute := DI mod 60;
      DI := DI / 60;
      Hour := DI;

      return
        Integer'Image (Year)
        & "-"
        & Integer'Image (Month)
        & "-"
        & Integer'Image (Day)
        & " "
        & Integer'Image (Hour)
        & ":"
        & Integer'Image (Minute)
        & ":"
        & Integer'Image (Second);
   end Time_Image;
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
      is (Size > 0 or Size_QB > 0);
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
         elsif Global_Task_Queue.Has_Work_Left then
            Global_Task_Queue.Pull (TI => Q, Count => Size);
            TI := Q (Local_Worker_Queue_Idx (Size));
            Size := Size - 1;
         --  Ada.Text_IO.Put_Line
         --    ("Worker Task Queue: Pop from global queue, new Size: "
         --     & Natural'Image (Size));
         else
            loop
               Process_QB;
               --  Print_States;
               if Size > 0 then
                  TI := Q (Local_Worker_Queue_Idx (Size));
                  Size := Size - 1;
                  exit;
               elsif Global_Task_Queue.Has_Work_Left then
                  Global_Task_Queue.Pull (TI => Q, Count => Size);
                  TI := Q (Local_Worker_Queue_Idx (Size));
                  Size := Size - 1;
                  exit;
               end if;
               delay 0.01; -- Yield to allow other tasks to run
            end loop;
         end if;
      end Pop;

      procedure Push_QB (TI : Task_Info) is
      begin
         if Size_QB = Local_Worker_Queue_Size_Total then
            -- Push the current queue buffer to the global task queue
            Global_Task_Queue.Push (QB);
            -- Reset the queue buffer
            for I
              in Local_Worker_Queue_Idx'First .. Local_Worker_Queue_Idx_Half
            loop
               QB (I) := QB (Local_Worker_Queue_Idx_Half + I);
            end loop;
            Size_QB := Size_QB / 2;
         end if;

         Size_QB := Size_QB + 1;
         QB (Local_Worker_Queue_Idx (Size_QB)) := TI;
      end Push_QB;

      procedure Process_QB is
         K : Local_Worker_Queue_Idx := 1;
      begin
         if Size_QB = 0 then
            return;
         end if;
         for I
           in Local_Worker_Queue_Idx'First .. Local_Worker_Queue_Idx (Size_QB)
         loop
            --  Ada.Text_IO.Put_Line
            --    ("Processing QB task "
            --     & Local_Worker_Queue_Idx'Image (I)
            --     & " with state "
            --     & Task_State'Image (QB (I).State));
            --  Ada.Text_IO.Put_Line
            --    ("Blocked Time: "
            --     & (if QB (I).Blocked_Time /= null
            --        then Time_Image (QB (I).Blocked_Time.all)
            --        else "null"));
            if QB (I).State = Blocked_Time
              and then QB (I).Blocked_Time.all <= Ada.Calendar.Clock
            then
               QB (I).State := Ready;
               -- If the task is blocked, push it back to the worker queue
               Push (QB (I));
            --  Ada.Text_IO.Put_Line
            --    ("Task "
            --     & Local_Worker_Queue_Idx'Image (I)
            --     & " is ready, pushed back to worker queue");

            else
               -- Otherwise, push it to the global task queue
               QB (K) := QB (I);
               K := K + 1;

               --  Ada.Text_IO.Put_Line
               --    ("Task "
               --     & Local_Worker_Queue_Idx'Image (I)
               --     & " is not ready, keeping in QB");
            end if;
         end loop;
         Size_QB := Natural (K) - 1;

         --  Print_States;
      end Process_QB;

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

      procedure Print_States is
      begin
         Ada.Text_IO.Put_Line ("Worker Task Queue States");

         for I in Local_Worker_Queue_Idx'First .. Local_Worker_Queue_Idx (Size)
         loop
            Ada.Text_IO.Put_Line
              ("Task "
               & Local_Worker_Queue_Idx'Image (I)
               & ": State = "
               & Task_State'Image (Q (I).State));
         end loop;

         Ada.Text_IO.Put_Line ("Blocked Queue Buffer States");
         for I
           in Local_Worker_Queue_Idx'First .. Local_Worker_Queue_Idx (Size_QB)
         loop
            Ada.Text_IO.Put_Line
              ("QB Task "
               & Local_Worker_Queue_Idx'Image (I)
               & ": State = "
               & Task_State'Image (QB (I).State));
            if QB (I).Blocked_Time /= null then
               Ada.Text_IO.Put_Line
                 ("Blocked Time: " & Time_Image (QB (I).Blocked_Time.all));
            else
               Ada.Text_IO.Put_Line ("Blocked Time: null");
            end if;
         end loop;

         Ada.Text_IO.Put_Line
           ("Total tasks in queue: "
            & Natural'Image (Size)
            & ", Total tasks in QB: "
            & Natural'Image (Size_QB));
      end Print_States;
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
      Sch_Cx   : constant Sched_Cx_Access :=
        new Sched_Cx'(W_Idx => W_Idx, Sched_Time => null, Cancelled => False);
   begin
      loop
         --  Ada.Text_IO.Put_Line
         --    ("Worker Task " & Worker_Idx'Image (W_Idx) & " waiting for task");
         Local_Work_Task_Queues (W_Idx).Process_QB;
         Local_Work_Task_Queues (W_Idx).Pop (TI);
         --  Local_Work_Task_Queues (W_Idx).Print_States;
         --  Ada.Text_IO.Put_Line
         --    ("Worker Task " & Worker_Idx'Image (W_Idx) & " processing task");
         Sch_Cx.Sched_Time := null;
         Sch_Cx.Cancelled := False;
         Workers_Busy.Set_Busy (W_Idx, True);
         TI.State := Running;
         TI.Fut.Poll (Sched_Cx => Sch_Cx, Finished => Finished);
         Workers_Busy.Set_Busy (W_Idx, False);
         --  Ada.Text_IO.Put_Line(if Sch_Cx.Sched_Time /= null then Time_Image (Sch_Cx.Sched_Time.all) else "No scheduled time");
         --  Ada.Text_IO.Put_Line(Boolean'Image(Sch_Cx.Cancelled));

         if not Finished then
            if Sch_Cx.Cancelled then
               TI.State := Cancelled;
               --  Ada.Text_IO.Put_Line
               --    ("Worker Task "
               --     & Worker_Idx'Image (W_Idx)
               --     & " cancelled task");
            -- drop
            elsif Sch_Cx.Sched_Time /= null then
               TI.State := Blocked_Time;
               TI.Blocked_Time := Sch_Cx.Sched_Time;
               Local_Work_Task_Queues (W_Idx).Push_QB (TI);
            else
               TI.State := Ready;
               Local_Work_Task_Queues (W_Idx).Push (TI);
            end if;
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
      Local_Work_Task_Queues (Worker_Idx'First).Push
        (TI => (Fut => Root, State => Ready, Blocked_Time => null));

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
            Ada.Text_IO.Put_Line ("No work left, exiting...");
            exit;
         end if;

         delay 0.01; -- Yield to allow other tasks to run
         --  Ada.Text_IO.Put_Line
         --    ("Waiting for workers to finish, work left: "
         --     & Boolean'Image (Work_Left));
      end loop;

      Ada.Text_IO.Put_Line ("All tasks completed.");

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

   procedure Wake_In_Future
     (Sched_Cx : Sched_Cx_Access;
      Time     : Ada.Calendar.Time := Ada.Calendar.Clock)
   is
      TI       : Task_Info;
      Finished : Boolean;
   begin
      if Sched_Cx = null then
         raise Constraint_Error with "Scheduler context cannot be null";
      end if;

      Sched_Cx.Sched_Time := new Ada.Calendar.Time'(Time);
   end Wake_In_Future;

   procedure Cancel (Sched_Cx : Sched_Cx_Access) is
   begin
      if Sched_Cx = null then
         raise Constraint_Error with "Scheduler context cannot be null";
      end if;
      --  Implement cancellation logic here if needed
      --  For now, we just raise an exception to indicate cancellation
      Sched_Cx.Cancelled := True;
   end Cancel;
end scheduler;
