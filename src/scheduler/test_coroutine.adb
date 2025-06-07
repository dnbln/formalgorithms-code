with Ada.Text_IO; use Ada.Text_IO;
with PCL;
pragma Elaborate_All (PCL);

--  Test where the completion of a coroutine resumes execution to in a chained
--  scenario.

--  When a coroutine terminates and its creator coroutine is still alive, we
--  expect execution to resume to its creator.

package body Test_Coroutine is

   ---------
   -- Run --
   ---------

   overriding
   procedure Run (D : in out Delegate_A) is
      pragma Unreferenced (D);
      D_B : constant Delegate_B_Access := new Delegate_B;
      C_B : constant Coroutine := Create (Delegate_Access (D_B));
   begin
      Put_Line ("Coroutine A: started, about to spawn B");
      C_B.Spawn;
      C_B.Switch;
      Put_Line ("Coroutine A: about to terminate");
   end Run;

   ---------
   -- Run --
   ---------

   overriding
   procedure Run (D : in out Delegate_B) is
      pragma Unreferenced (D);
   begin
      Put_Line ("Coroutine B: started, about to terminate");
   end Run;

   procedure Test_Coroutine is
      Init : constant Integer := PCL.Thread_Init;
      D_A  : constant Delegate_A_Access := new Delegate_A;
      C_A  : constant Coroutine := Create (Delegate_Access (D_A));
   begin
      if Init /= 0 then
         Put_Line ("Thread_Init failed with code " & Integer'Image (Init));
         return;
      end if;
      Put_Line ("Main: about to spawn A");
      C_A.Spawn;
      C_A.Switch;
      Put_Line ("Main: about to terminate");
   end Test_Coroutine;

end Test_Coroutine;
