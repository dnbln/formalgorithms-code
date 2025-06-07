with Ada.Text_IO; use Ada.Text_IO;
with scheduler;

package body scheduler_demo is
   type Demo_Root_Future_State is (Initial, Running, Completed);

   type Demo_Root_Future is new scheduler.Future with record
      State  : Demo_Root_Future_State;
      Result : Boolean := False;
   end record;

   overriding
   procedure Poll (F : in out Demo_Root_Future; Finished : out Boolean) is
   begin
      case F.State is
         when Initial =>
            -- Transition to Running state
            F.State := Running;
            Finished := False;
            Put_Line ("Demo Root Future initialized, transitioning to Running state.");

         when Running =>
            -- Simulate some work being done
            Put_Line ("Running Demo Root Future...");
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
      Future: scheduler.Future_Access := new Demo_Root_Future'(State => Initial, Result => False);
   begin
      scheduler.Spawn_RT (Future);
   end Run_Demo;
end scheduler_demo;
