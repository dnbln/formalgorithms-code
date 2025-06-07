with Ada.Text_IO; use Ada.Text_IO;
with scheduler;

package body scheduler_demo is
   procedure Demo_Root is
   begin
      Put_Line ("Hello from the scheduler demo!");
   end Demo_Root;

   package Sch is new scheduler (Root_Function => Demo_Root);

   procedure Run_Demo is
   begin
      Sch.Spawn_RT;
   end Run_Demo;
end scheduler_demo;
