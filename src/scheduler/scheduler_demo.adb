with Ada.Text_IO; use Ada.Text_IO;
with scheduler;
with Ada.Calendar; use Ada.Calendar;

package body scheduler_demo is
   type Demo_Root_Future_State is (Initial, Running, Wait_One, Waiting, Cancelling, Wait_Again, Waiting_Again, Completed);

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

            for I in 1 .. 1_000 loop
               scheduler.Spawn
                 (Sched_Cx => Sched_Cx,
                  F        =>
                    new Demo_Root_Future'
                      (State => Running, Id => I, Result => False));
            end loop;

            Finished := False;
            Put_Line
              ("Demo Root Future initialized, transitioning to Running state.");

         when Running =>
            -- Simulate some work being done
            --  Put_Line ("Running Demo Root Future..." & Integer'Image (F.Id));
            -- Transition to Completed state
            F.State := Wait_One;
            F.Result := True;
            Finished := False;

         when Wait_One =>
            -- Wait for a condition or event
            --  Put_Line ("Demo Root Future is waiting...");
            scheduler.Wake_In_Future
              (Sched_Cx => Sched_Cx, Time => Ada.Calendar.Clock + 20.0);
            F.State := Waiting;
            Finished := False;
         
         when Waiting =>
            -- Check if the condition or event is met
            Put_Line ("Demo Root Future finished waiting.");
            if F.Id = 0 then
               F.State := Wait_Again;
               Put_Line ("Demo Root Future will wait again.");
            else
               F.State := Cancelling;
            end if;

            Finished := False;
            -- Simulate condition being met after some time
         
         when Cancelling => 
            -- Handle cancellation logic
            Put_Line ("Demo Root Future is being cancelled.");
            scheduler.Cancel (Sched_Cx);
            Finished := False;
         
         when Wait_Again =>
            -- Wait again for some condition or event
            Put_Line ("Demo Root Future is waiting again...");
            scheduler.Wake_In_Future
              (Sched_Cx => Sched_Cx, Time => Ada.Calendar.Clock + 1.0);
            F.State := Waiting_Again;
            Finished := False;

         when Waiting_Again =>
            -- Check if the condition or event is met again
            Put_Line ("Demo Root Future finished waiting again.");
            F.State := Completed;
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
