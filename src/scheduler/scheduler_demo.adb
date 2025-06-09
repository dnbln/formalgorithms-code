with Ada.Text_IO;       use Ada.Text_IO;
with scheduler;
with Ada.Calendar;      use Ada.Calendar;
with Scheduler.IO;
with Scheduler.IO.File;
with Ada.Strings;       use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;

package body scheduler_demo is
   type Demo_Root_Future_State is (Initial, Running, Completed);

   type FileReadFuture_State is (Initial, Waiting, Completed);

   type FileReadFuture is new scheduler.Future with record
      State : FileReadFuture_State;
      Id    : Natural := 0;
      Fi    : Scheduler.IO.File.File_Access;
   end record;

   overriding
   procedure Poll
     (F        : in out FileReadFuture;
      Sched_Cx : scheduler.Sched_Cx_Access;
      Finished : out Boolean) is
   begin
      case F.State is
         when Initial =>
            F.Fi :=
              Scheduler.IO.File.Open_Read
                (Path =>
                   ("example" & Trim (Natural'Image (F.Id), Both) & ".txt"));
            F.State := Waiting;
            Finished := False;

            Scheduler.IO.File.Wake_On_IO (Sched_Cx => Sched_Cx, File => F.Fi);

         when Waiting =>
            -- Simulate waiting for a file read operation
            --  Put_Line ("FileReadFuture is waiting for file read operation...");

            declare
               Buffer : Scheduler.Bytes (1 .. 1024);
               Count  : Natural;
            begin
               Scheduler.IO.File.Read
                 (File => F.Fi, Buffer => Buffer, Count => Count);
               Put_Line
                 ("Read " & Integer'Image (Count) & " bytes from file.");

               if Count = 0 then
                  -- If no bytes were read, we assume the file read is complete
                  F.State := Completed;
               else
                  Scheduler.IO.File.Wake_On_IO
                    (Sched_Cx => Sched_Cx, File => F.Fi);
               end if;
            end;

            -- Here you would normally check if the file read is complete
            -- For demonstration, we simulate completion after some time
            Finished := False;

         when Completed =>
            -- Finalize the task
            Put_Line ("FileReadFuture completed file read operation.");

            Scheduler.IO.File.Close (F.Fi);

            Finished := True;
      end case;
   end Poll;

   type Demo_Root_Future is new scheduler.Future with record
      State  : Demo_Root_Future_State;
      Id     : Natural := 0;
      Result : Boolean := False;
   end record;

   overriding
   procedure Poll
     (F        : in out Demo_Root_Future;
      Sched_Cx : scheduler.Sched_Cx_Access;
      Finished : out Boolean) is
   begin
      case F.State is
         when Initial =>
            -- Transition to Running state
            F.State := Running;

            for I in 0 .. 9 loop
               -- Spawn multiple FileReadFuture tasks
               Scheduler.Spawn
                 (Sched_Cx => Sched_Cx,
                  F        =>
                    new FileReadFuture'
                      (State => Initial, Id => I, Fi => null));
            end loop;
            Finished := False;
            Put_Line
              ("Demo Root Future initialized, transitioning to Running state.");

         when Running =>
            -- Simulate some work being done
            --  Put_Line ("Running Demo Root Future..." & Integer'Image (F.Id));
            -- Transition to Completed state
            F.State := Completed;
            F.Result := True;
            Finished := False;

         when Completed =>
            -- Finalize the task
            Put_Line ("Demo Root Future completed.");
            Finished := True;
      end case;
   end Poll;

   procedure Run_Demo is
      Future : scheduler.Future_Access :=
        new Demo_Root_Future'(State => Initial, Id => 0, Result => False);
   begin
      scheduler.Spawn_RT (Future);
   end Run_Demo;
end scheduler_demo;
