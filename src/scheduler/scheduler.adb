with Ada.Calendar; use Ada.Calendar;
with Ada.Exceptions;
with Ada.Text_IO;
with scheduler_io_h;

package body Scheduler is
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

   protected body Task_Id_Generator is
      procedure Get_Next (Id : out Task_Id) is
      begin
         Current_Id := Current_Id + 1;
         Id := Current_Id;
      end Get_Next;
   end Task_Id_Generator;

   function Get_Next_Task_Id return Task_Id is
      Id : Task_Id;
   begin
      Task_Id_Generator.Get_Next (Id);
      return Id;
   end Get_Next_Task_Id;

   function Task_Is_Blocked_But_Ready
     (TI : Task_Info; Poll_R : Poll_Results) return Boolean is
   begin
      if TI.State = Blocked_Time
        and then TI.Blocked_Time /= null
        and then TI.Blocked_Time.all <= Ada.Calendar.Clock
      then
         return True;
      elsif TI.State = Blocked_IO then
         return False;
      else
         return False;
      end if;
   end Task_Is_Blocked_But_Ready;

   protected body Global_Task_Queue is
      function Has_Work_Left return Boolean
      is (First < Last or else Size_QB > 0);

      procedure Push_One (TI : Task_Info) is
      begin
         --  if P = First then
         --     raise Constraint_Error
         --       with "Global Task Queue is full, cannot push more tasks";
         --  end if;
         Global_TI_Array
           (Global_Task_Info_Idx
              ((Last mod Global_Task_Info_Size_Total) + 1)) :=
           TI;
         Last := Last + 1;
      --  Ada.Text_IO.Put_Line
      --    ("Global Task Queue: Pushed one task, new Last index: "
      --     & Natural'Image (Last));
      end Push_One;

      procedure Push (TI : Local_Worker_Task_Info_Array) is
      begin
         --  if P = First then
         --     raise Constraint_Error
         --       with "Global Task Queue is full, cannot push more tasks";
         --  end if;
         for I in Local_Worker_Queue_Idx'First .. Local_Worker_Queue_Idx_Half
         loop
            Push_One (TI (I));
         end loop;

      --  Ada.Text_IO.Put_Line
      --    ("Global Task Queue: Pushed "
      --     & Natural'Image (Local_Worker_Queue_Size_Half)
      --     & " tasks, new Last index: "
      --     & Natural'Image (Last));
      end Push;

      --  entry Pull
      --    (TI : in out Local_Worker_Task_Info_Array; Count : out Natural)
      --    when First < Last

      --  is
      --     Size    : constant Natural := Last - First;
      --     Pulling : Natural := Local_Worker_Queue_Size_Half;
      --  begin
      --     Count := 0;
      --     --  Ada.Text_IO.Put_Line
      --     --    ("Global Task Queue: Pulling tasks, current Size: "
      --     --     & Natural'Image (Size)
      --     --     & ", First index: "
      --     --     & Natural'Image (First)
      --     --     & ", Last: "
      --     --     & Natural'Image (Last));
      --     if Size = 0 then
      --        return;
      --     end if;
      --     if Size < Pulling then
      --        Pulling := Size;
      --     end if;
      --     for I
      --       in Local_Worker_Queue_Idx'First
      --          .. Local_Worker_Queue_Idx'First
      --             + Local_Worker_Queue_Idx (Pulling)
      --             - 1
      --     loop
      --        TI (I) :=
      --          Global_TI_Array (Global_Task_Info_Idx (First + Natural (I)));
      --        Count := Count + 1;
      --     end loop;

      --     First := First + Local_Worker_Queue_Size_Half;
      --  --  Ada.Text_IO.Put_Line
      --  --    ("Global Task Queue: Pulled "
      --  --     & Natural'Image (Count)
      --  --     & " tasks, new First index: "
      --  --     & Natural'Image (First));
      --  end Pull;

      procedure Poll_IO (Poll_R : out Poll_Results) is
      begin
         if IO_Q = null then
            IO_Q := Create_IO_Blocked_Queue;
         end if;
         Poll_R := Poll_IO_Blocked_Queue (KQ => IO_Q);
      end Poll_IO;

      procedure Try_Pull
        (TI : in out Local_Worker_Task_Info_Array; Count : out Natural)
      is
         Poll_R : Poll_Results;
      begin
         Poll_IO (Poll_R => Poll_R);
         --  Ada.Text_IO.Put_Line
         --    ("Global Task Queue: Trying to pull tasks, current First index: "
         --     & Natural'Image (First)
         --     & ", Last index: "
         --     & Natural'Image (Last));

         Process_QB (Poll_R => Poll_R);
         --  Ada.Text_IO.Put_Line
         --    ("Global Task Queue: Trying to pull tasks, current First index: "
         --     & Natural'Image (First)
         --     & ", Last index: "
         --     & Natural'Image (Last));
         if First < Last then
            declare
               Size    : constant Natural := Last - First;
               Pulling : Natural := Local_Worker_Queue_Size_Half;
            begin
               Count := 0;
               --  Ada.Text_IO.Put_Line
               --    ("Global Task Queue: Pulling tasks, current Size: "
               --     & Natural'Image (Size)
               --     & ", First index: "
               --     & Natural'Image (First)
               --     & ", Last: "
               --     & Natural'Image (Last));
               if Size < Pulling then
                  Pulling := Size;
               end if;
               for I
                 in Local_Worker_Queue_Idx'First
                    .. Local_Worker_Queue_Idx'First
                       + Local_Worker_Queue_Idx (Pulling)
                       - 1
               loop
                  TI (I) :=
                    Global_TI_Array
                      (Global_Task_Info_Idx
                         ((First + Natural (I) - 1)
                          mod Global_Task_Info_Size_Total
                          + 1));
                  Count := Count + 1;
               end loop;

               pragma Assert (Count = Pulling);
               First := First + Pulling;
            end;
         else
            Count := 0;
         end if;

      --  Ada.Text_IO.Put_Line
      --    ("Global Task Queue: Try_Pull completed, Count: "
      --     & Natural'Image (Count)
      --     & ", First index: "
      --     & Natural'Image (First)
      --     & ", Last index: "
      --     & Natural'Image (Last));
      end;

      procedure Push_QB (TI : Local_Worker_Task_Info_Array) is
      begin
         --  Ada.Text_IO.Put_Line
         --    ("Global Task Queue: Pushing QB, current Last_B index: "
         --     & Natural'Image (Last_B)
         --     & ", First_B index: "
         --     & Natural'Image (First_B));
         --  if P = First_B then
         --     raise Constraint_Error
         --       with "Global Task Queue is full, cannot push more tasks";
         --  end if;
         for I in Local_Worker_Queue_Idx'First .. Local_Worker_Queue_Idx_Half
         loop
            Global_TI_B_Array (Global_Task_Info_Idx (Size_QB + Natural (I))) :=
              TI (I);
         end loop;
         Size_QB := Size_QB + Local_Worker_Queue_Size_Half;
      --  Ada.Text_IO.Put_Line
      --    ("Global Task Queue: Pushed QB, new Size_QB: "
      --     & Natural'Image (Size_QB));
      end Push_QB;

      procedure Process_QB (Poll_R : Poll_Results) is
         K : Global_Task_Info_Idx := 1;
      begin
         --  Ada.Text_IO.Put_Line
         --    ("Processing Global Blocked Queue Buffer, current size: "
         --     & Natural'Image (Size_QB));
         if Size_QB = 0 then
            return;
         end if;
         for I in Global_Task_Info_Idx'First .. Global_Task_Info_Idx (Size_QB)
         loop
            --  Ada.Text_IO.Put_Line
            --    ("Processing QB task "
            --     & Global_Task_Info_Idx'Image (I)
            --     & " with state "
            --     & Task_State'Image (Global_TI_B_Array (I).State));
            if Task_Is_Blocked_But_Ready (Global_TI_B_Array (I), Poll_R) then
               Global_TI_B_Array (I).State := Ready;
               -- If the task is blocked, push it back to the worker queue
               --  Ada.Text_IO.Put_Line
               --    ("Task "
               --     & Global_Task_Info_Idx'Image (I)
               --     & " is ready, pushed back to worker queue");
               Push_One (Global_TI_B_Array (I));
            else
               -- Otherwise, keep it in the global blocked queue buffer
               Global_TI_B_Array (K) := Global_TI_B_Array (I);
               if Natural (K) < Size_QB then
                  K := K + 1;
               end if;
            end if;
         end loop;
         Size_QB := Natural (K) - 1;
      --  Ada.Text_IO.Put_Line
      --    ("Global Task Queue: Processed QB, new Last_B index: "
      --     & Natural'Image (Last_B));
      end Process_QB;
   end Global_Task_Queue;

   protected body Worker_Task_Queue is
      function Has_Work_Left return Boolean
      is (Size > 0 or Size_QB > 0);
      procedure Push (TI : Task_Info) is
      begin
         pragma Assert (TI.State = Ready);
         --  Ada.Text_IO.Put_Line
         --    ("Worker Task Queue: Pushing task, current Size: "
         --     & Natural'Image (Size)
         --     & ", Size_QB: "
         --     & Natural'Image (Size_QB));

         if Size = Local_Worker_Queue_Size_Total then
            Global_Task_Queue.Push (Q);
            for I
              in Local_Worker_Queue_Idx'First .. Local_Worker_Queue_Idx_Half
            loop
               Q (I) := Q (Local_Worker_Queue_Idx_Half + I);
            end loop;
            Size := Size - Local_Worker_Queue_Size_Half;
         end if;

         Size := Size + 1;
         Q (Local_Worker_Queue_Idx (Size)) := TI;

      end Push;
      procedure Pop (TI : out Task_Info; Poll_R : Poll_Results) is
      begin
         --  Ada.Text_IO.Put_Line
         --    ("Worker Task Queue: Popping task, current Size: "
         --     & Natural'Image (Size)
         --     & ", Size_QB: "
         --     & Natural'Image (Size_QB));
         if Size > 0 then
            TI := Q (Local_Worker_Queue_Idx (Size));
            Size := Size - 1;
         --  elsif Global_Task_Queue.Has_Work_Left then
         --     Global_Task_Queue.Pull (TI => Q, Count => Size);
         --     TI := Q (Local_Worker_Queue_Idx (Size));
         --     Size := Size - 1;
         --  Ada.Text_IO.Put_Line
         --    ("Worker Task Queue: Pop from global queue, new Size: "
         --     & Natural'Image (Size));

         else
            --  Ada.Text_IO.Put_Line
            --    ("Worker Task Queue: No tasks to pop, waiting for work");
            loop
               Process_QB (Poll_R => Poll_R);
               --  Print_States;
               --  Ada.Text_IO.Put_Line
               --    ("Worker Task Queue: Waiting for tasks, current Size: "
               --     & Natural'Image (Size)
               --     & ", Size_QB: "
               --     & Natural'Image (Size_QB)
               --     & " (after processing QB)");
               if Size > 0 then
                  TI := Q (Local_Worker_Queue_Idx (Size));
                  Size := Size - 1;
                  exit;
               else
                  --  Ada.Text_IO.Put_Line
                  --    ("Worker Task Queue: No tasks available, trying to pull from global queue");
                  Global_Task_Queue.Try_Pull (TI => Q, Count => Size);
                  if Size > 0 then
                     TI := Q (Local_Worker_Queue_Idx (Size));
                     Size := Size - 1;
                     exit;
                  end if;
               end if;
               --  delay 0.01; -- Yield to allow other tasks to run
            end loop;
         end if;
      end Pop;

      procedure Push_QB (TI : Task_Info) is
      begin
         pragma Assert (TI.State = Blocked_Time or else TI.State = Blocked_IO);
         --  Ada.Text_IO.Put_Line
         --    ("Worker Task Queue: Pushing QB, current Size_QB: "
         --     & Natural'Image (Size_QB)
         --     & ", Size: "
         --     & Natural'Image (Size));
         if Size_QB = Local_Worker_Queue_Size_Total then
            -- Push the current queue buffer to the global task queue
            --  Ada.Text_IO.Put_Line
            --    ("Worker Task Queue: Pushing QB to global task queue, current Size_QB: "
            --     & Natural'Image (Size_QB));
            Global_Task_Queue.Push_QB (QB);
            -- Reset the queue buffer
            for I
              in Local_Worker_Queue_Idx'First .. Local_Worker_Queue_Idx_Half
            loop
               QB (I) := QB (Local_Worker_Queue_Idx_Half + I);
            end loop;
            Size_QB := Size_QB - Local_Worker_Queue_Size_Half;
         --  Ada.Text_IO.Put_Line
         --    ("Worker Task Queue: QB pushed to global task queue, new Size_QB: "
         --     & Natural'Image (Size_QB));

         end if;

         Size_QB := Size_QB + 1;
         QB (Local_Worker_Queue_Idx (Size_QB)) := TI;

      --  Ada.Text_IO.Put_Line
      --    ("Worker Task Queue: Pushed QB, new Size_QB: "
      --     & Natural'Image (Size_QB)
      --     & ", Size: "
      --     & Natural'Image (Size));
      end Push_QB;

      procedure Process_QB (Poll_R : Poll_Results) is
         K         : Local_Worker_Queue_Idx := 1;
         Keep_Size : Boolean := False;
      begin
         --  Ada.Text_IO.Put_Line
         --    ("Processing Blocked Queue Buffer, current size: "
         --     & Natural'Image (Size_QB));
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
            --  Ada.Text_IO.Put_Line
            --    ("Current Time: " & Time_Image (Ada.Calendar.Clock));
            if Task_Is_Blocked_But_Ready (QB (I), Poll_R) then
               QB (I).State := Ready;
               -- If the task is blocked, push it back to the worker queue
               --  Ada.Text_IO.Put_Line
               --    ("Task "
               --     & Local_Worker_Queue_Idx'Image (I)
               --     & " is ready, pushed back to worker queue");
               Push (QB (I));
            else
               -- Otherwise, push it to the global task queue
               QB (K) := QB (I);
               if Natural (K) < Size_QB then
                  K := K + 1;
               elsif Natural (K) = Size_QB then
                  Keep_Size := True;
               end if;

               --  Ada.Text_IO.Put_Line
               --    ("Task "
               --     & Local_Worker_Queue_Idx'Image (I)
               --     & " is not ready, keeping in QB");
            end if;
         end loop;
         if not Keep_Size then
            Size_QB := Natural (K) - 1;
         end if;

      --  Ada.Text_IO.Put_Line
      --    ("Worker Task Queue: Processed QB, new Size_QB: "
      --     & Natural'Image (Size_QB));

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
        new Sched_Cx'
          (W_Idx      => W_Idx,
           Sched_Time => null,
           Sched_IO   => null,
           Cancelled  => False);
      IO_Queue : IO_Blocked_Queue_Access := Create_IO_Blocked_Queue;
      Poll_R   : Poll_Results;
   begin
      loop
         Poll_R := Poll_IO_Blocked_Queue (KQ => IO_Queue);
         --  Ada.Text_IO.Put_Line
         --    ("Worker Task " & Worker_Idx'Image (W_Idx) & " waiting for task");
         Local_Work_Task_Queues (W_Idx).Process_QB (Poll_R);
         Local_Work_Task_Queues (W_Idx).Pop (TI, Poll_R);
         --  Local_Work_Task_Queues (W_Idx).Print_States;
         --  Ada.Text_IO.Put_Line
         --    ("Worker Task " & Worker_Idx'Image (W_Idx) & " processing task");
         Sch_Cx.Sched_Time := null;
         Sch_Cx.Sched_IO := null;
         Sch_Cx.Cancelled := False;
         Workers_Busy.Set_Busy (W_Idx, True);
         TI.State := Running;
         begin
            TI.Fut.Poll (Sched_Cx => Sch_Cx, Finished => Finished);
         exception
            when E : others =>
               --  Handle any exceptions that may occur during polling
               Finished := True;
               TI.State := Cancelled;

               Ada.Text_IO.Put_Line
                 ("Worker Task "
                  & Worker_Idx'Image (W_Idx)
                  & " encountered an error: "
                  & Ada.Exceptions.Exception_Information (E));
         end;
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
            elsif Sch_Cx.Sched_IO /= null then
               TI.State := Blocked_IO;
               TI.Blocked_IO := Sch_Cx.Sched_IO;
               --  Ada.Text_IO.Put_Line
               --    ("Worker Task "
               --     & Worker_Idx'Image (W_Idx)
               --     & " blocked task on IO");
               Local_Work_Task_Queues (W_Idx).Push_QB (TI);
            elsif Sch_Cx.Sched_Time /= null then
               TI.State := Blocked_Time;
               TI.Blocked_Time := Sch_Cx.Sched_Time;
               Local_Work_Task_Queues (W_Idx).Push_QB (TI);
            --  Ada.Text_IO.Put_Line
            --    ("Worker Task "
            --     & Worker_Idx'Image (W_Idx)
            --     & " blocked task until "
            --     & Time_Image (Sch_Cx.Sched_Time.all));
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
      begin
         Run_Main_Root_Delegate (W_Idx);
      exception
         when E : others =>
            --  Handle any exceptions that may occur during polling
            Ada.Text_IO.Put_Line
              ("Worker Task "
               & Worker_Idx'Image (W_Idx)
               & " encountered an error: "
               & Ada.Exceptions.Exception_Information (E));
      end;
   --  Ada.Text_IO.Put_Line
   --    ("Worker Task " & Worker_Idx'Image (W_Idx) & " finished");
   end Worker_Task;

   procedure Spawn_RT (Root : Future_Access) is
      Workers   : array (Worker_Idx) of Worker_Task;
      Work_Left : Boolean := True;
   begin
      Local_Work_Task_Queues (Worker_Idx'First).Push
        (TI =>
           (Fut          => Root,
            State        => Ready,
            Blocked_Time => null,
            Blocked_IO   => null,
            T_Id         => Get_Next_Task_Id));

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
      TI :=
        (Fut          => F,
         State        => Ready,
         Blocked_Time => null,
         Blocked_IO   => null,
         T_Id         => Get_Next_Task_Id);
      Local_Work_Task_Queues (Sched_Cx.W_Idx).Push (TI);
   end Spawn;

   procedure Wake_In_Future
     (Sched_Cx : Sched_Cx_Access;
      Time     : Ada.Calendar.Time := Ada.Calendar.Clock) is
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

   function Create_IO_Blocked_Queue return IO_Blocked_Queue_Access
   is (new IO_Blocked_Queue'(KQueue => scheduler_io_h.create_kqueue));

   procedure Add_Read_To_IO_Blocked_Queue
     (KQ     : IO_Blocked_Queue_Access;
      FD     : Interfaces.C.int;
      T_Info : Udata_Info_Access)
   is
      Result : Interfaces.C.int;
   begin
      Result :=
        scheduler_io_h.register_event
          (KQ.KQueue, FD, sys_event_h.EVFILT_READ, T_Info'Address);

      if Integer (Result) < 0 then
         raise Program_Error with "Error registering read event";
      end if;

   end Add_Read_To_IO_Blocked_Queue;

   procedure Add_Write_To_IO_Blocked_Queue
     (KQ     : IO_Blocked_Queue_Access;
      FD     : Interfaces.C.int;
      T_Info : Udata_Info_Access)
   is
      Result : Interfaces.C.int;
   begin
      Result :=
        scheduler_io_h.register_event
          (KQ.KQueue, FD, sys_event_h.EVFILT_WRITE, T_Info'Address);
      if Integer (Result) < 0 then
         raise Program_Error with "Error registering write event";
      end if;
   end Add_Write_To_IO_Blocked_Queue;

   function Poll_IO_Blocked_Queue
     (KQ : IO_Blocked_Queue_Access) return Poll_Results
   is
      Events     : Poll_Result_Buffer;
      Num_Events : Interfaces.C.int;
   begin
      Num_Events :=
        scheduler_io_h.poll_events
          (KQ.KQueue,
           Events'Address,
           Interfaces.C.int (Poll_Result_Buffer'Length));
      --  Ada.Text_IO.Put_Line
      --    ("Scheduler: Polling IO blocked queue, number of events: "
      --     & Integer'Image (Integer (Num_Events)));
      if Integer (Num_Events) < 0 then
         raise Program_Error with "Error polling IO blocked queue";
      end if;
      return (Events => Events, Count => Integer (Num_Events));
   end Poll_IO_Blocked_Queue;

   procedure Wake_On_IO
     (Sched_Cx : Scheduler.Sched_Cx_Access; File : Interfaces.C.int) is
   begin
      Sched_Cx.Sched_IO := new Interfaces.C.int'(File);
   end Wake_On_IO;
end Scheduler;
