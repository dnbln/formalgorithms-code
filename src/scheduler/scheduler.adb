with Ada.Calendar;            use Ada.Calendar;
with Ada.Exceptions;
with Ada.Text_IO;
with Interfaces.C.Strings;    use Interfaces.C.Strings;
with scheduler_io_h;
with sys_utypes_uintptr_t_h;
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

      procedure Finish is
      begin
         Finished := Finished + 1;
      end Finish;

      function All_Finished return Boolean is
      begin
         --  Ada.Text_IO.Put_Line
         --    ("Checking if all tasks are finished, Current_Id: "
         --     & Task_Id'Image (Current_Id)
         --     & ", Finished: "
         --     & Natural'Image (Finished));

         return (Finished = Natural (Current_Id));
      end All_Finished;
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

   procedure Task_Is_Blocked_But_Ready
     (TI                         : Task_Info_Access;
      Poll_R                     : Poll_Result;
      Result                     : out Boolean;
      Count_Data_Available_If_IO : out Natural;
      IO_Did_EOF                 : out Boolean) is
   begin
      Count_Data_Available_If_IO := 0;
      IO_Did_EOF := False;
      Result := False;
      --  Ada.Text_IO.Put_Line
      --    ("Checking if task "
      --     & Task_Id'Image (TI.T_Id)
      --     & " is blocked but ready, State: "
      --     & Task_State'Image (TI.State));
      if TI.State = Blocked_IO then
         if Poll_R.ident = unsigned_long (TI.Blocked_IO.FD)
           and then Poll_R.filter
                    = Filter_For_Blocking_Type (TI.Blocked_IO.Blocked_Type)
         then
            --  If the task is blocked on IO and the event is ready, return True

            --  Ada.Text_IO.Put_Line
            --    ("Unblocking task " & Task_Id'Image (TI.T_Id));
            Result := True;
            --  Ada.Text_IO.Put_Line
            --    ("Task "
            --     & Task_Id'Image (TI.T_Id)
            --     & " is blocked on IO, FD: "
            --     & int'Image (TI.Blocked_IO.FD)
            --     & ", Type: "
            --     & Blocked_IO_Type'Image (TI.Blocked_IO.Blocked_Type)
            --     & ", Data: "
            --     & sys_utypes_uintptr_t_h.intptr_t'Image
            --         (Poll_R.Events (I).data));
            Count_Data_Available_If_IO := Natural (Poll_R.data);
            --  Ada.Text_IO.Put_Line
            --    ("Data available for task "
            --     & Task_Id'Image (TI.T_Id)
            --     & ": "
            --     & Natural'Image (Count_Data_Available_If_IO));
            IO_Did_EOF :=
              (Mod_Int (Poll_R.flags) and Mod_Int (sys_event_h.EV_EOF))
              /= 0; -- Check if EOF flag is set

         end if;
      end if;
   end Task_Is_Blocked_But_Ready;

   procedure Add_Block_To_IO_Blocked_Queue
     (KQ : IO_Blocked_Queue_Access; TI : Task_Info_Access)
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
              (KQ => KQ, FD => B_Info.FD, T_Info => TI);

         when Write =>
            Add_Write_To_IO_Blocked_Queue
              (KQ => KQ, FD => B_Info.FD, T_Info => TI);
      end case;
   end Add_Block_To_IO_Blocked_Queue;

   procedure Remove_Block_From_IO_Blocked_Queue
     (KQ : IO_Blocked_Queue_Access; TI : Task_Info_Access)
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

      procedure Push_One (TI : Task_Info_Access) is
      begin
         --  if P = First then
         --     raise Constraint_Error
         --       with "Global Task Queue is full, cannot push more tasks";
         --  end if;
         if TI.State /= Ready then
            raise Constraint_Error
              with "Cannot push task that is not in Ready state";
         end if;
         Global_TI_Array
           (Global_Task_Info_Idx
              ((Last mod Global_Task_Info_Size_Total) + 1)) :=
           TI;
         Last := Last + 1;
      --  Ada.Text_IO.Put_Line
      --    ("Global Task Queue: Pushed one task, new Last index: "
      --     & Natural'Image (Last));
      end Push_One;

      procedure Push_QB_One (TI : Task_Info_Access) is
      begin
         --  Ada.Text_IO.Put_Line
         --    ("Global Task Queue: Pushing one task to QB, current Size_QB: "
         --     & Natural'Image (Size_QB));
         if Size_QB = Global_Task_Info_Size_Total then
            raise Constraint_Error
              with "Global Task Queue is full, cannot push more tasks";
         end if;

         if TI.State /= Blocked_Time and then TI.State /= Blocked_IO then
            raise Constraint_Error
              with
                "Cannot push task that is not in Blocked_Time or Blocked_IO state";
         end if;

         Size_QB := Size_QB + 1;
         Global_TI_B_Array (Global_Task_Info_Idx (Size_QB)) := TI;
         if IO_Q = null then
            IO_Q := Create_IO_Blocked_Queue;
         end if;
         Add_Block_To_IO_Blocked_Queue (KQ => IO_Q, TI => TI);
      end Push_QB_One;

      procedure Push (TI : in out Local_Worker_Task_Info_Array) is
      begin
         --  if P = First then
         --     raise Constraint_Error
         --       with "Global Task Queue is full, cannot push more tasks";
         --  end if;
         for I in Local_Worker_Queue_Idx'First .. Local_Worker_Queue_Idx_Half
         loop
            if TI (I).State = Ready then
               Push_One (TI (I));
               TI (I) := null;
            elsif TI (I).State = Blocked_Time or else TI (I).State = Blocked_IO
            then
               Push_QB_One (TI (I));
               TI (I) := null;
            end if;
         end loop;

      --  Ada.Text_IO.Put_Line
      --    ("Global Task Queue: Pushed "
      --     & Natural'Image (Local_Worker_Queue_Size_Half)
      --     & " tasks, new Last index: "
      --     & Natural'Image (Last));
      end Push;

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
                  Global_TI_Array
                    (Global_Task_Info_Idx
                       ((First + Natural (I) - 1)
                        mod Global_Task_Info_Size_Total
                        + 1)) :=
                    null;
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
         K                          : Natural := 0;
         Is_Ready                   : Boolean := False;
         Count_Data_Available_If_IO : Natural := 0;
         IO_Did_EOF                 : Boolean := False;
         TI_Acc                     : Task_Info_Access;
      begin
         --  Ada.Text_IO.Put_Line
         --    ("Processing Global Blocked Queue Buffer, current size: "
         --     & Natural'Image (Size_QB));
         if Size_QB = 0 then
            return;
         end if;
         if Poll_R.Count > 0 then
            for I in Poll_R.Events'First .. Poll_R.Count loop
               --  Ada.Text_IO.Put_Line
               --    ("Processing Poll Result for FD: "
               --     & int'Image (Poll_R.Events (I).ident)
               --     & ", Filter: "
               --     & int'Image (Poll_R.Events (I).filter));
               TI_Acc :=
                 Task_Info_Access
                   (TI_Conv.To_Pointer (Poll_R.Events (I).udata));
               Task_Is_Blocked_But_Ready
                 (TI_Acc,
                  Poll_R.Events (I),
                  Is_Ready,
                  Count_Data_Available_If_IO,
                  IO_Did_EOF);
               if Is_Ready then
                  TI_Acc.State := Ready;
                  if TI_Acc.Blocked_IO /= null then
                     TI_Acc.Blocked_IO.Data := Count_Data_Available_If_IO;
                     TI_Acc.Blocked_IO.EOF := IO_Did_EOF;
                  end if;
               end if;
            end loop;
         end if;
         for I in Global_Task_Info_Idx'First .. Global_Task_Info_Idx (Size_QB)
         loop
            --  Ada.Text_IO.Put_Line
            --    ("Processing QB task "
            --     & Global_Task_Info_Idx'Image (I)
            --     & " with state "
            --     & Task_State'Image (Global_TI_B_Array (I).State));
            if Global_TI_B_Array (I).State = Blocked_Time
              and then Global_TI_B_Array (I).Blocked_Time /= null
              and then Global_TI_B_Array (I).Blocked_Time.all
                       <= Ada.Calendar.Clock
            then
               Global_TI_B_Array (I).State := Ready;
            end if;
            if Global_TI_B_Array (I).State = Ready then
               -- If the task is blocked, push it back to the worker queue
               --  Ada.Text_IO.Put_Line
               --    ("Task "
               --     & Global_Task_Info_Idx'Image (I)
               --     & " is ready, pushed back to worker queue");
               Push_One (Global_TI_B_Array (I));
            else
               -- Otherwise, keep it in the global blocked queue buffer
               K := K + 1;
               Global_TI_B_Array (Global_Task_Info_Idx (K)) :=
                 Global_TI_B_Array (I);
            end if;
         end loop;
         Size_QB := K;
      --  Ada.Text_IO.Put_Line
      --    ("Global Task Queue: Processed QB, new Last_B index: "
      --     & Natural'Image (Last_B));
      end Process_QB;

      procedure Print_States is
      begin
         Ada.Text_IO.Put_Line
           ("Global Task Queue States: First = "
            & Natural'Image (First)
            & ", Last = "
            & Natural'Image (Last)
            & ", Size_QB = "
            & Natural'Image (Size_QB));
         if Last > First then
            for I
              in Global_Task_Info_Idx (First + 1)
                 .. Global_Task_Info_Idx (Last)
            loop
               Ada.Text_IO.Put_Line
                 ("Task "
                  & Task_Id'Image (Global_TI_Array (I).T_Id)
                  & ": State = "
                  & Task_State'Image (Global_TI_Array (I).State));
               if Global_TI_Array (I).Blocked_IO /= null then
                  Ada.Text_IO.Put_Line
                    ("Blocked IO: FD = "
                     & int'Image (Global_TI_Array (I).Blocked_IO.FD)
                     & ", Type = "
                     & Blocked_IO_Type'Image
                         (Global_TI_Array (I).Blocked_IO.Blocked_Type));
                  if Global_TI_Array (I).Blocked_IO.Data /= 0 then
                     Ada.Text_IO.Put_Line
                       ("Data Available: "
                        & Natural'Image (Global_TI_Array (I).Blocked_IO.Data));
                  end if;
                  if Global_TI_Array (I).Blocked_IO.EOF then
                     Ada.Text_IO.Put_Line ("EOF reached");
                  end if;
               else
                  Ada.Text_IO.Put_Line ("No Blocked IO for this task");
               end if;
            end loop;
         end if;
         if Size_QB > 0 then
            for I
              in Global_Task_Info_Idx'First .. Global_Task_Info_Idx (Size_QB)
            loop
               Ada.Text_IO.Put_Line
                 ("Task "
                  & Global_Task_Info_Idx'Image (I)
                  & ": State = "
                  & Task_State'Image (Global_TI_B_Array (I).State));

               if Global_TI_B_Array (I).Blocked_IO /= null then
                  Ada.Text_IO.Put_Line
                    ("Blocked IO: FD = "
                     & int'Image (Global_TI_B_Array (I).Blocked_IO.FD)
                     & ", Type = "
                     & Blocked_IO_Type'Image
                         (Global_TI_B_Array (I).Blocked_IO.Blocked_Type));
                  if Global_TI_B_Array (I).Blocked_IO.Data /= 0 then
                     Ada.Text_IO.Put_Line
                       ("Data Available: "
                        & Natural'Image
                            (Global_TI_B_Array (I).Blocked_IO.Data));
                  end if;
                  if Global_TI_B_Array (I).Blocked_IO.EOF then
                     Ada.Text_IO.Put_Line ("EOF reached");
                  end if;
               else
                  Ada.Text_IO.Put_Line ("No Blocked IO for this task");
               end if;
            end loop;
         end if;
      end Print_States;
   end Global_Task_Queue;

   protected body Worker_Task_Queue is
      function Has_Work_Left return Boolean
      is (Size > 0 or else Size_QB > 0);

      procedure Push (TI : Task_Info_Access) is
         Last_Idx : Local_Worker_Queue_Idx := 1;
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
               if Q (I) = null then
                  Q (I) := Q (Local_Worker_Queue_Idx_Half + I);
               elsif Q (I).State = Running then
                  Last_Idx := Local_Worker_Queue_Idx_Half + I;
               else
                  raise Program_Error
                    with "Worker Task Queue: Invalid task state during push";
               end if;
            end loop;
            Size := Size - Local_Worker_Queue_Size_Half;
            if Last_Idx /= 1 then
               Size := Size + 1;
               Q (Local_Worker_Queue_Idx (Size)) := Q (Last_Idx);
            end if;
         end if;

         Size := Size + 1;
         Q (Local_Worker_Queue_Idx (Size)) := TI;

      end Push;

      procedure Finish_Current_Task is
      begin
         --  Ada.Text_IO.Put_Line
         --    ("Worker Task Queue: Finishing current task, current Size: "
         --     & Natural'Image (Size)
         --     & ", Size_QB: "
         --     & Natural'Image (Size_QB));
         if Clock_Position > 0 and then Clock_Position <= Size then
            Q (Local_Worker_Queue_Idx (Clock_Position)) := null;
         else
            raise Program_Error with "No current task to finish";
         end if;
      end Finish_Current_Task;

      procedure Attempt_Enqueue_From_Global (Count : out Natural) is
      begin
         Global_Task_Queue.Try_Pull (Q, Size);
         Count := Size;
      end Attempt_Enqueue_From_Global;

      procedure Current_Task_Finished is
      begin
         Q (Local_Worker_Queue_Idx (Clock_Position)) := null;
      end Current_Task_Finished;
      function Has_More_Tasks return Boolean is
      begin
         return Clock_Position < Size;
      end Has_More_Tasks;

      procedure Next_Task (TI : out Task_Info_Access) is
      begin
         --  Ada.Text_IO.Put_Line
         --    ("Worker Task Queue: Popping task, current Size: "
         --     & Natural'Image (Size)
         --     & ", Size_QB: "
         --     & Natural'Image (Size_QB));
         if Size > 0 then
            Stealable_Tasks := Clock_Position;
            Clock_Position := Clock_Position + 1;
            pragma Assert (Clock_Position <= Size);
            pragma
              Assert (Q (Local_Worker_Queue_Idx (Clock_Position)) /= null);
            pragma
              Assert
                (Q (Local_Worker_Queue_Idx (Clock_Position)).State = Ready);
            Q (Local_Worker_Queue_Idx (Clock_Position)).State := Running;
            TI := Q (Local_Worker_Queue_Idx (Clock_Position));
         --  elsif Global_Task_Queue.Has_Work_Left then
         --     Global_Task_Queue.Pull (TI => Q, Count => Size);
         --     TI := Q (Local_Worker_Queue_Idx (Size));
         --     Size := Size - 1;
         --  Ada.Text_IO.Put_Line
         --    ("Worker Task Queue: Pop from global queue, new Size: "
         --     & Natural'Image (Size));

         end if;
      end Next_Task;

      procedure Reset_Clock is
      begin
         --  Ada.Text_IO.Put_Line
         --    ("Worker Task Queue: Resetting clock, current Size: "
         --     & Natural'Image (Size)
         --     & ", Size_QB: "
         --     & Natural'Image (Size_QB));
         Clock_Position := 0;
         Stealable_Tasks := 0;
      end Reset_Clock;

      procedure Next_Task_Opt (TI : out Task_Info_Access; Set : out Boolean) is
      begin
         if Clock_Position < Size then
            Next_Task (TI);
            Set := True;
         else
            Set := False;
         end if;
      end Next_Task_Opt;

      procedure Push_QB (TI : Task_Info_Access) is
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
            if Q (I) /= null then
               if Q (I).State = Blocked_Time or else Q (I).State = Blocked_IO
               then
                  Push_QB (Q (I));
               elsif Q (I).State = Ready then
                  K := K + 1;
                  Q (Local_Worker_Queue_Idx (K)) := Q (I);
               end if;
            end if;
         end loop;
         Size := K;
         Reset_Clock;
      end Flush_Blocked;

      procedure Process_QB is
         K                    : Natural := 0;
         Keep_Size            : Boolean := False;
         Poll_R               : Poll_Results;
         Is_Ready             : Boolean := False;
         Data_Available_If_IO : Natural := 0;
         IO_Did_EOF           : Boolean := False;
         TI_Acc               : aliased Task_Info_Access;
      begin
         --  Ada.Text_IO.Put_Line
         --    ("Processing Blocked Queue Buffer, current size: "
         --     & Natural'Image (Size_QB));
         if Size_QB = 0 then
            return;
         end if;
         Poll_IO (Poll_R => Poll_R);
         if Poll_R.Count > 0 then
            for I in Poll_R.Events'First .. Poll_R.Count loop
               TI_Acc :=
                 Task_Info_Access
                   (TI_Conv.To_Pointer (Poll_R.Events (I).udata));
               Task_Is_Blocked_But_Ready
                 (TI_Acc,
                  Poll_R.Events (I),
                  Is_Ready,
                  Data_Available_If_IO,
                  IO_Did_EOF);
               if Is_Ready then
                  --  Ada.Text_IO.Put_Line
                  --    ("Task "
                  --     & Task_Id'Image (TI_Acc.T_Id)
                  --     & " is ready, pushing back to worker queue");
                  TI_Acc.State := Ready;
                  if TI_Acc.Blocked_IO /= null then
                     TI_Acc.Blocked_IO.Data := Data_Available_If_IO;
                     TI_Acc.Blocked_IO.EOF := IO_Did_EOF;
                  end if;
               else
                  raise Program_Error
                    with
                      "Task is blocked but not ready, yet it was returned by kqueue, cannot process";
               end if;
            end loop;
         end if;
         for I
           in Local_Worker_Queue_Idx'First .. Local_Worker_Queue_Idx (Size_QB)
         loop
            if QB (I).State = Blocked_Time
              and then QB (I).Blocked_Time /= null
              and then QB (I).Blocked_Time.all <= Ada.Calendar.Clock
            then
               QB (I).State := Ready;
            end if;

            if QB (I).State = Ready then
               Push (QB (I));
               QB (I) := null;
            else
               -- Otherwise, push it to the global task queue
               K := K + 1;
               QB (Local_Worker_Queue_Idx (K)) := QB (I);

               --  Ada.Text_IO.Put_Line
               --    ("Task "
               --     & Local_Worker_Queue_Idx'Image (I)
               --     & " is not ready, keeping in QB");
            end if;
         end loop;
         Size_QB := K;

      --  Ada.Text_IO.Put_Line
      --    ("Worker Task Queue: Processed QB, new Size_QB: "
      --     & Natural'Image (Size_QB));

      --  Print_States;
      end Process_QB;

      procedure Steal
        (TI : in out Local_Worker_Task_Info_Array; Count : out Natural) is
      begin
         --  Ada.Text_IO.Put_Line
         --    ("Worker Task Queue: Stealing tasks, current Size: "
         --     & Natural'Image (Size));
         Count := 0;
         if Size <= 1 or else Stealable_Tasks = 0 then
            return;
         end if;
         for I
           in Local_Worker_Queue_Idx'First
              .. Local_Worker_Queue_Idx (Stealable_Tasks)
         loop
            if Q (I) /= null and then Q (I).State = Ready then
               Count := Count + 1;
               TI (Local_Worker_Queue_Idx (Count)) := Q (I);
               Q (I) := null;

               if Count >= Size / 2 then
                  exit;
               end if;
            end if;
         end loop;
      end Steal;

      procedure Steal_From
        (Victim : access Worker_Task_Queue; Count : out Natural) is
      begin
         pragma Assert (Size = 0);
         Victim.Steal (Q, Count);
         Size := Count;
      end Steal_From;

      procedure Push_Queue (TI : Local_Worker_Task_Info_Array; Count : Natural)
      is
      begin
         pragma Assert (Size = 0);
         pragma Assert (Count > 0);
         Size := Count;
         for I
           in Local_Worker_Queue_Idx'First .. Local_Worker_Queue_Idx (Count)
         loop
            Q (I) := TI (I);
         end loop;
      end Push_Queue;

      procedure Print_States is
      begin
         if Size > 0 then
            Ada.Text_IO.Put_Line ("Worker Task Queue States");

            for I
              in Local_Worker_Queue_Idx'First .. Local_Worker_Queue_Idx (Size)
            loop
               Ada.Text_IO.Put_Line
                 ("Task "
                  & Task_Id'Image (Q (I).T_Id)
                  & ": State = "
                  & Task_State'Image (Q (I).State));
               if QB (I).Blocked_IO /= null then
                  Ada.Text_IO.Put_Line
                    ("Blocked IO: FD = "
                     & Integer'Image (Integer (QB (I).Blocked_IO.FD))
                     & ", Type = "
                     & Blocked_IO_Type'Image (QB (I).Blocked_IO.Blocked_Type)
                     & ", Data = "
                     & Natural'Image (QB (I).Blocked_IO.Data)
                     & ", EOF = "
                     & Boolean'Image (QB (I).Blocked_IO.EOF));
               else
                  Ada.Text_IO.Put_Line ("Blocked IO: null");
               end if;
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
                  & Task_Id'Image (QB (I).T_Id)
                  & ": State = "
                  & Task_State'Image (QB (I).State));
               if QB (I).Blocked_Time /= null then
                  Ada.Text_IO.Put_Line
                    ("Blocked Time: " & Time_Image (QB (I).Blocked_Time.all));
               else
                  Ada.Text_IO.Put_Line ("Blocked Time: null");
               end if;
               if QB (I).Blocked_IO /= null then
                  Ada.Text_IO.Put_Line
                    ("Blocked IO: FD = "
                     & Integer'Image (Integer (QB (I).Blocked_IO.FD))
                     & ", Type = "
                     & Blocked_IO_Type'Image (QB (I).Blocked_IO.Blocked_Type)
                     & ", Data = "
                     & Natural'Image (QB (I).Blocked_IO.Data)
                     & ", EOF = "
                     & Boolean'Image (QB (I).Blocked_IO.EOF));
               else
                  Ada.Text_IO.Put_Line ("Blocked IO: null");
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

   procedure Enqueue_Work_From_Other_Queues (W_Idx : Worker_Idx) is
      Count  : Natural := 0;
      Victim : access Worker_Task_Queue;
      Q      : Local_Worker_Task_Info_Array;
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
      for I in Worker_Idx'Range loop
         if I /= W_Idx then
            Victim := Local_Work_Task_Queues (I)'Access;
            --  Ada.Text_IO.Put_Line
            --    ("Worker Task "
            --     & Worker_Idx'Image (W_Idx)
            --     & " stealing from Worker Task "
            --     & Worker_Idx'Image (I));
            if I < W_Idx then
               Local_Work_Task_Queues (W_Idx).Steal_From
                 (Victim, Count => Count);
            else
               Victim.Steal (TI => Q, Count => Count);
               if Count /= 0 then
                  Local_Work_Task_Queues (W_Idx).Push_Queue
                    (TI => Q, Count => Count);
               end if;
            end if;
            if Count > 0 then
               --  Ada.Text_IO.Put_Line
               --    ("Worker Task "
               --     & Worker_Idx'Image (W_Idx)
               --     & " stole "
               --     & Natural'Image (Count)
               --     & " tasks from Worker Task "
               --     & Worker_Idx'Image (I));
               --  Ada.Text_IO.Put_Line
               --    ("Worker Task "
               --     & Worker_Idx'Image (W_Idx)
               --     & " stole "
               --     & Natural'Image (Count)
               --     & " tasks from Worker Task "
               --     & Worker_Idx'Image (I));
               return;
            end if;
         end if;
      end loop;

      -- delay 10ms if nothing else worked (no work currently)
      delay IDLE_DELAY;
   end Enqueue_Work_From_Other_Queues;

   procedure Print_All_States is
   begin
      Ada.Text_IO.Put_Line ("Global Task Queue States:");
      Global_Task_Queue.Print_States;
      Ada.Text_IO.Put_Line ("Worker Task Queues States:");
      for I in Worker_Idx'First .. Worker_Idx'Last loop
         Ada.Text_IO.Put_Line
           ("Worker Task Queue " & Worker_Idx'Image (I) & " States:");
         Local_Work_Task_Queues (I).Print_States;
      end loop;
   end Print_All_States;

   task body Worker_Task is
      W_Idx    : Worker_Idx;
      TI       : Task_Info_Access;
      Finished : Boolean;
      Sch_Cx   : Sched_Cx_Access;
      Has_Work : Boolean;
   begin
      accept Start (Idx : Worker_Idx) do
         W_Idx := Idx;
      end Start;
      --  Ada.Text_IO.Put_Line
      --    ("Worker Task " & Worker_Idx'Image (W_Idx) & " started");
      Sch_Cx :=
        new Sched_Cx'
          (W_Idx                => W_Idx,
           Sched_Time           => null,
           Sched_IO             => null,
           Prev_Blocked_IO_Info => null,
           Cancelled            => False);
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
         Local_Work_Task_Queues (W_Idx).Next_Task_Opt
           (TI => TI, Set => Has_Work);
         --  Local_Work_Task_Queues (W_Idx).Print_States;

         if not Has_Work then
            --  Ada.Text_IO.Put_Line
            --    ("Worker Task "
            --     & Worker_Idx'Image (W_Idx)
            --     & " has no work, waiting for tasks");
            --  Print_All_States;
            Enqueue_Work_From_Other_Queues (W_Idx => W_Idx);
         else
            while Has_Work loop
               --  Ada.Text_IO.Put_Line
               --    ("Worker Task " & Worker_Idx'Image (W_Idx) & " waiting for task");
               --  Local_Work_Task_Queues (W_Idx).Print_States;
               --  Ada.Text_IO.Put_Line
               --    ("Worker Task "
               --     & Worker_Idx'Image (W_Idx)
               --     & " processing task "
               --     & Task_Id'Image (TI.T_Id));
               Sch_Cx.Sched_Time := null;
               Sch_Cx.Sched_IO := null;
               Sch_Cx.Cancelled := False;
               Sch_Cx.Prev_Blocked_IO_Info := TI.Blocked_IO;
               begin
                  TI.Fut.Poll (Sched_Cx => Sch_Cx, Finished => Finished);
               exception
                  when E : others =>
                     --  Handle any exceptions that may occur during polling
                     Finished := True;

                     Ada.Text_IO.Put_Line
                       ("Worker Task "
                        & Worker_Idx'Image (W_Idx)
                        & " encountered an error: "
                        & Ada.Exceptions.Exception_Information (E));
               end;
               --  Ada.Text_IO.Put_Line(if Sch_Cx.Sched_Time /= null then Time_Image (Sch_Cx.Sched_Time.all) else "No scheduled time");
               --  Ada.Text_IO.Put_Line(Boolean'Image(Sch_Cx.Cancelled));
               TI.Blocked_IO := Sch_Cx.Sched_IO;
               TI.Blocked_Time := Sch_Cx.Sched_Time;

               if Finished then
                  TI.State := Completed;
                  Task_Id_Generator.Finish;
                  Local_Work_Task_Queues (W_Idx).Current_Task_Finished;
               elsif Sch_Cx.Cancelled then
                  TI.State := Cancelled;
                  Task_Id_Generator.Finish;
                  Local_Work_Task_Queues (W_Idx).Current_Task_Finished;
               --  Ada.Text_IO.Put_Line
               --    ("Worker Task "
               --     & Worker_Idx'Image (W_Idx)
               --     & " cancelled task with ID: "
               --     & Task_Id'Image (TI.T_Id));
               -- drop
               elsif Sch_Cx.Sched_IO /= null then
                  TI.State := Blocked_IO;
               --  Ada.Text_IO.Put_Line
               --    ("Worker Task "
               --     & Worker_Idx'Image (W_Idx)
               --     & " blocked task on IO");
               elsif Sch_Cx.Sched_Time /= null then
                  TI.State := Blocked_Time;
               --  Ada.Text_IO.Put_Line
               --    ("Worker Task "
               --     & Worker_Idx'Image (W_Idx)
               --     & " blocked task until "
               --     & Time_Image (Sch_Cx.Sched_Time.all));
               else
                  TI.State := Ready;
               end if;

               Local_Work_Task_Queues (W_Idx).Next_Task_Opt
                 (TI => TI, Set => Has_Work);
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
      Workers : array (Worker_Idx) of Worker_Task;
   begin
      Local_Work_Task_Queues (Worker_Idx'First).Push
        (TI =>
           new Task_Info'
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
         if Task_Id_Generator.All_Finished then
            Ada.Text_IO.Put_Line ("No work left, exiting...");
            exit;
         end if;

         delay 1.0; -- Check every second
      end loop;

      for I in Workers'Range loop
         Workers (I).Stop;
      end loop;

      Ada.Text_IO.Put_Line ("All tasks completed.");

   --  Workers(1).Start(f);
   end Spawn_RT;

   procedure Spawn (Sched_Cx : Sched_Cx_Access; F : Future_Access) is
      TI : Task_Info_Access;
   begin
      if Sched_Cx = null then
         raise Constraint_Error with "Scheduler context cannot be null";
      end if;
      if F = null then
         raise Constraint_Error with "Future cannot be null";
      end if;
      TI :=
        new Task_Info'
          (Fut          => F,
           State        => Ready,
           Blocked_Time => null,
           Blocked_IO   => null,
           T_Id         => Get_Next_Task_Id);
      Local_Work_Task_Queues (Sched_Cx.W_Idx).Push (TI);
   --  Ada.Text_IO.Put_Line
   --    ("Spawned task with ID: " & Task_Id'Image (TI.T_Id));
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
      T_Info : Task_Info_Access)
   is
      Result : Interfaces.C.int;
   begin
      Result :=
        scheduler_io_h.register_event
          (KQ.KQueue,
           FD,
           sys_event_h.EVFILT_READ,
           TI_Conv.To_Address (TI_Conv.Object_Pointer (T_Info)));

      if Integer (Result) < 0 then
         raise Program_Error with "Error registering read event";
      end if;

   end Add_Read_To_IO_Blocked_Queue;

   procedure Add_Write_To_IO_Blocked_Queue
     (KQ     : IO_Blocked_Queue_Access;
      FD     : Interfaces.C.int;
      T_Info : Task_Info_Access)
   is
      Result : Interfaces.C.int;
   begin
      Result :=
        scheduler_io_h.register_event
          (KQ.KQueue,
           FD,
           sys_event_h.EVFILT_WRITE,
           TI_Conv.To_Address (TI_Conv.Object_Pointer (T_Info)));
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
        new Blocked_IO_Info'
          (FD => File, Blocked_Type => Read, Data => 0, EOF => False);
   end Wake_On_IO_Read;

   procedure Wake_On_IO_Write
     (Sched_Cx : Scheduler.Sched_Cx_Access; File : Interfaces.C.int) is
   begin
      Sched_Cx.Sched_IO :=
        new Blocked_IO_Info'
          (FD => File, Blocked_Type => Write, Data => 0, EOF => False);
   end Wake_On_IO_Write;

   function Get_Available_Data
     (Sched_Cx : Scheduler.Sched_Cx_Access) return Natural is
   begin
      if Sched_Cx.Prev_Blocked_IO_Info = null then
         raise Constraint_Error with "Scheduler context IO info is null";
      end if;
      return Sched_Cx.Prev_Blocked_IO_Info.Data;
   end Get_Available_Data;

   function IO_EOF (Sched_Cx : Scheduler.Sched_Cx_Access) return Boolean is
   begin
      if Sched_Cx.Prev_Blocked_IO_Info = null then
         raise Constraint_Error with "Scheduler context IO info is null";
      end if;
      return Sched_Cx.Prev_Blocked_IO_Info.EOF;
   end IO_EOF;

   procedure Perr (Msg : String) is
      M : chars_ptr := New_String (Msg);
   begin
      scheduler_io_h.call_perror (M);
      Free (M);
   end Perr;
end Scheduler;
