with Ada.Calendar;            use Ada.Calendar;
with Ada.Exceptions;
with Ada.Text_IO;
with scheduler_io_h;
with sys_utypes_uuintptr_t_h; use sys_utypes_uuintptr_t_h;
with Interfaces.C;            use Interfaces.C;
with sys_utypes_uint16_t_h;

package body Scheduler is
   IDLE_DELAY : constant := 0.05;  --  Idle delay in seconds, 50ms

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

   function Filter_For_Blocking_Type
     (Blocked_Type : Blocked_IO_Type) return sys_utypes_uint16_t_h.int16_t is
   begin
      case Blocked_Type is
         when Read =>
            return sys_event_h.EVFILT_READ;

         when Write =>
            return sys_event_h.EVFILT_WRITE;
      end case;
   end Filter_For_Blocking_Type;

   function Task_Is_Blocked_But_Ready
     (TI : Task_Info; Poll_R : Poll_Results) return Boolean is
   begin
      if TI.State = Blocked_Time
        and then TI.Blocked_Time /= null
        and then TI.Blocked_Time.all <= Ada.Calendar.Clock
      then
         return True;
      elsif TI.State = Blocked_IO then
         for I in 1 .. Poll_R.Count loop
            if Poll_R.Events (I).ident = unsigned_long (TI.Blocked_IO.FD)
              and then Poll_R.Events (I).filter
                       = Filter_For_Blocking_Type (TI.Blocked_IO.Blocked_Type)
            then
               --  If the task is blocked on IO and the event is ready, return True
               return True;
            end if;
         end loop;
         return False;
      else
         return False;
      end if;
   end Task_Is_Blocked_But_Ready;

   procedure Add_Block_To_IO_Blocked_Queue
     (KQ : IO_Blocked_Queue_Access; TI : Task_Info)
   is
      B_Info : Blocked_IO_Info;
   begin
      if TI.Blocked_IO = null then
         return;
      end if;

      B_Info := TI.Blocked_IO.all;

      case B_Info.Blocked_Type is
         when Read =>
            Add_Read_To_IO_Blocked_Queue
              (KQ     => KQ,
               FD     => B_Info.FD,
               T_Info => new Udata_Info'(T_Id => TI.T_Id));

         when Write =>
            Add_Write_To_IO_Blocked_Queue
              (KQ     => KQ,
               FD     => B_Info.FD,
               T_Info => new Udata_Info'(T_Id => TI.T_Id));
      end case;
   end Add_Block_To_IO_Blocked_Queue;

   procedure Remove_Block_From_IO_Blocked_Queue
     (KQ : IO_Blocked_Queue_Access; TI : Task_Info)
   is
      B_Info : Blocked_IO_Info;
   begin
      if TI.Blocked_IO = null then
         return;
      end if;

      B_Info := TI.Blocked_IO.all;

      case B_Info.Blocked_Type is
         when Read =>
            Remove_Read_From_IO_Blocked_Queue (KQ => KQ, FD => B_Info.FD);

         when Write =>
            Remove_Write_From_IO_Blocked_Queue (KQ => KQ, FD => B_Info.FD);
      end case;
   end Remove_Block_From_IO_Blocked_Queue;

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

      procedure Push_QB_One (TI : Task_Info) is
      begin
         --  Ada.Text_IO.Put_Line
         --    ("Global Task Queue: Pushing one task to QB, current Size_QB: "
         --     & Natural'Image (Size_QB));
         if Size_QB = Global_Task_Info_Size_Total then
            raise Constraint_Error
              with "Global Task Queue is full, cannot push more tasks";
         end if;

         Size_QB := Size_QB + 1;
         Global_TI_B_Array (Global_Task_Info_Idx (Size_QB)) := TI;
         Add_Block_To_IO_Blocked_Queue (KQ => IO_Q, TI => TI);
      end Push_QB_One;

      procedure Push (TI : Local_Worker_Task_Info_Array) is
      begin
         --  if P = First then
         --     raise Constraint_Error
         --       with "Global Task Queue is full, cannot push more tasks";
         --  end if;
         for I in Local_Worker_Queue_Idx'First .. Local_Worker_Queue_Idx_Half
         loop
            if TI (I).State = Ready then
               Push_One (TI (I));
            else
               Push_QB_One (TI (I));
            end if;
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
            Poll_R := (Events => (others => <>), Count => 0);
            return;
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

         if IO_Q = null then
            IO_Q := Create_IO_Blocked_Queue;
         end if;

         for I in Local_Worker_Queue_Idx'First .. Local_Worker_Queue_Idx_Half
         loop
            Add_Block_To_IO_Blocked_Queue (KQ => IO_Q, TI => TI (I));
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

      function Make_Tick_Info return Tick_Info
      is ((Current => 0, Count => Size));

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

      procedure Update_Tick_Task (TI : Task_Info; Tick : Tick_Info) is
      begin
         Q (Local_Worker_Queue_Idx (Tick.Current)) := TI;
      end Update_Tick_Task;

      procedure Attempt_Enqueue_From_Global (Count : out Natural) is
      begin
         if Size /= 0 then
            raise Program_Error
              with
                "Worker Task Queue is not empty, cannot enqueue from global queue";
         end if;
         Global_Task_Queue.Try_Pull (Q, Size);
         Count := Size;
      end Attempt_Enqueue_From_Global;

      procedure Next_Task (TI : out Task_Info; Tick : in out Tick_Info) is
      begin
         --  Ada.Text_IO.Put_Line
         --    ("Worker Task Queue: Popping task, current Size: "
         --     & Natural'Image (Size)
         --     & ", Size_QB: "
         --     & Natural'Image (Size_QB));
         if Size > 0 then
            Tick.Current := Tick.Current + 1;
            TI := Q (Local_Worker_Queue_Idx (Tick.Current));
         --  elsif Global_Task_Queue.Has_Work_Left then
         --     Global_Task_Queue.Pull (TI => Q, Count => Size);
         --     TI := Q (Local_Worker_Queue_Idx (Size));
         --     Size := Size - 1;
         --  Ada.Text_IO.Put_Line
         --    ("Worker Task Queue: Pop from global queue, new Size: "
         --     & Natural'Image (Size));

         end if;
      end Next_Task;

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
               Remove_Block_From_IO_Blocked_Queue (KQ => IO_Q, TI => QB (I));
               QB (I) := QB (Local_Worker_Queue_Idx_Half + I);
            end loop;
            Size_QB := Size_QB - Local_Worker_Queue_Size_Half;
         --  Ada.Text_IO.Put_Line
         --    ("Worker Task Queue: QB pushed to global task queue, new Size_QB: "
         --     & Natural'Image (Size_QB));

         end if;

         Size_QB := Size_QB + 1;
         QB (Local_Worker_Queue_Idx (Size_QB)) := TI;
         if IO_Q = null then
            IO_Q := Create_IO_Blocked_Queue;
         end if;
         Add_Block_To_IO_Blocked_Queue (KQ => IO_Q, TI => TI);

      --  Ada.Text_IO.Put_Line
      --    ("Worker Task Queue: Pushed QB, new Size_QB: "
      --     & Natural'Image (Size_QB)
      --     & ", Size: "
      --     & Natural'Image (Size));
      end Push_QB;

      procedure Poll_IO (Poll_R : out Poll_Results) is
      begin
         if IO_Q = null then
            Poll_R := (Events => (others => <>), Count => 0);
            return;
         end if;
         Poll_R := Poll_IO_Blocked_Queue (KQ => IO_Q);
      end Poll_IO;

      procedure Flush_Blocked is
         K : Natural := 0;
      begin
         if Size = 0 then
            return;
         end if;
         for I in Local_Worker_Queue_Idx'First .. Local_Worker_Queue_Idx (Size)
         loop
            if Q (I).State = Blocked_Time or else Q (I).State = Blocked_IO then
               Push_QB (Q (I));
            elsif Q (I).State = Ready then
               K := K + 1;
               Q (Local_Worker_Queue_Idx (K)) := Q (I);
            end if;
         end loop;
         Size := K;
      end Flush_Blocked;

      procedure Process_QB is
         K         : Local_Worker_Queue_Idx := 1;
         Keep_Size : Boolean := False;
         Poll_R    : Poll_Results;
      begin
         --  Ada.Text_IO.Put_Line
         --    ("Processing Blocked Queue Buffer, current size: "
         --     & Natural'Image (Size_QB));
         if Size_QB = 0 then
            return;
         end if;
         Poll_IO (Poll_R => Poll_R);
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
         if Size > 0 then
            Ada.Text_IO.Put_Line ("Worker Task Queue States");

            for I
              in Local_Worker_Queue_Idx'First .. Local_Worker_Queue_Idx (Size)
            loop
               Ada.Text_IO.Put_Line
                 ("Task "
                  & Local_Worker_Queue_Idx'Image (I)
                  & ": State = "
                  & Task_State'Image (Q (I).State));
            end loop;
         end if;

         if Size_QB > 0 then
            Ada.Text_IO.Put_Line ("Blocked Queue Buffer States");
            for I
              in Local_Worker_Queue_Idx'First
                 .. Local_Worker_Queue_Idx (Size_QB)
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
         end if;

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

   function Tick_Has_More_Work (Tick : Tick_Info) return Boolean
   is (Tick.Current < Tick.Count);

   procedure Enqueue_Work_From_Other_Queues (W_Idx : Worker_Idx) is
      Count : Natural := 0;
   begin
      Local_Work_Task_Queues (W_Idx).Attempt_Enqueue_From_Global
        (Count => Count);
      if Count > 0 then
         --  Ada.Text_IO.Put_Line
         --    ("Worker Task "
         --     & Worker_Idx'Image (W_Idx)
         --     & " enqueued "
         --     & Natural'Image (Count)
         --     & " tasks from global queue");
         return;
      end if;

      -- try and steal tasks from other worker queues

      -- delay 10ms if nothing else worked (no work currently)
      delay IDLE_DELAY;
   end Enqueue_Work_From_Other_Queues;

   task body Worker_Task is
      W_Idx    : Worker_Idx;
      TI       : Task_Info;
      Finished : Boolean;
      Sch_Cx   : Sched_Cx_Access;
      Tick     : Tick_Info;
   begin
      accept Start (Idx : Worker_Idx) do
         W_Idx := Idx;
      end Start;
      --  Ada.Text_IO.Put_Line
      --    ("Worker Task " & Worker_Idx'Image (W_Idx) & " started");
      Sch_Cx :=
        new Sched_Cx'
          (W_Idx      => W_Idx,
           Sched_Time => null,
           Sched_IO   => null,
           Cancelled  => False);
      Main_Loop :
      loop
         select
            accept Stop do
               null;
            end Stop;
            exit Main_Loop;
         or
            delay 0.0; -- Yield to allow other tasks to run
         end select;
         Local_Work_Task_Queues (W_Idx).Process_QB;
         Tick := Local_Work_Task_Queues (W_Idx).Make_Tick_Info;

         if not Tick_Has_More_Work (Tick) then
            Enqueue_Work_From_Other_Queues (W_Idx => W_Idx);
         else
            while Tick_Has_More_Work (Tick) loop
               --  Ada.Text_IO.Put_Line
               --    ("Worker Task " & Worker_Idx'Image (W_Idx) & " waiting for task");
               Local_Work_Task_Queues (W_Idx).Next_Task (TI, Tick);
               --  Local_Work_Task_Queues (W_Idx).Print_States;
               --  Ada.Text_IO.Put_Line
               --    ("Worker Task "
               --     & Worker_Idx'Image (W_Idx)
               --     & " processing task");
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

               if Finished then
                  TI.State := Completed;
               elsif Sch_Cx.Cancelled then
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
               elsif Sch_Cx.Sched_Time /= null then
                  TI.State := Blocked_Time;
                  TI.Blocked_Time := Sch_Cx.Sched_Time;
               --  Ada.Text_IO.Put_Line
               --    ("Worker Task "
               --     & Worker_Idx'Image (W_Idx)
               --     & " blocked task until "
               --     & Time_Image (Sch_Cx.Sched_Time.all));
               else
                  TI.State := Ready;
               end if;
               Local_Work_Task_Queues (W_Idx).Update_Tick_Task (TI, Tick);
            end loop;
            Local_Work_Task_Queues (W_Idx).Flush_Blocked;
         end if;
      end loop Main_Loop;
   exception
      when E : others =>
         --  Handle any exceptions that may occur during polling
         Ada.Text_IO.Put_Line
           ("Worker Task "
            & Worker_Idx'Image (W_Idx)
            & " encountered an error: "
            & Ada.Exceptions.Exception_Information (E));
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

      for I in Workers'Range loop
         Workers (I).Stop;
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

   procedure Remove_Read_From_IO_Blocked_Queue
     (KQ : IO_Blocked_Queue_Access; FD : Interfaces.C.int)
   is
      Result : Interfaces.C.int;
   begin
      Result :=
        scheduler_io_h.unregister_event
          (KQ.KQueue, FD, sys_event_h.EVFILT_READ);
      if Integer (Result) < 0 then
         raise Program_Error with "Error unregistering read event";
      end if;
   end Remove_Read_From_IO_Blocked_Queue;

   procedure Remove_Write_From_IO_Blocked_Queue
     (KQ : IO_Blocked_Queue_Access; FD : Interfaces.C.int)
   is
      Result : Interfaces.C.int;
   begin
      Result :=
        scheduler_io_h.unregister_event
          (KQ.KQueue, FD, sys_event_h.EVFILT_WRITE);
      if Integer (Result) < 0 then
         raise Program_Error with "Error unregistering write event";
      end if;
   end Remove_Write_From_IO_Blocked_Queue;

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
      if Integer (Num_Events) < 0 then
         raise Program_Error with "Error polling IO blocked queue";
      end if;
      --  Ada.Text_IO.Put_Line
      --    ("Scheduler: Polling IO blocked queue, number of events: "
      --     & Integer'Image (Integer (Num_Events)));
      return (Events => Events, Count => Integer (Num_Events));
   end Poll_IO_Blocked_Queue;

   procedure Wake_On_IO_Read
     (Sched_Cx : Scheduler.Sched_Cx_Access; File : Interfaces.C.int) is
   begin
      Sched_Cx.Sched_IO :=
        new Blocked_IO_Info'(FD => File, Blocked_Type => Read);
   end Wake_On_IO_Read;

   procedure Wake_On_IO_Write
     (Sched_Cx : Scheduler.Sched_Cx_Access; File : Interfaces.C.int) is
   begin
      Sched_Cx.Sched_IO :=
        new Blocked_IO_Info'(FD => File, Blocked_Type => Write);
   end Wake_On_IO_Write;
end Scheduler;
