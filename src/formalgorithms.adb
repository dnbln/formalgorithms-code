pragma Partition_Elaboration_Policy (Concurrent);
with qsort;
with Ada.Text_IO;
with Test_Coroutine;
pragma Elaborate_All (Test_Coroutine);
with Types;
with hmap_int_to_int; use hmap_int_to_int;
with pub_sub_int_channel;
--  with test_pub_sub;
with scheduler;
with scheduler_demo;
pragma Elaborate_All (scheduler);

procedure Formalgorithms is
   t : Types.IArr := (0, 10, 45, 1, -10, -100);
   m : Hash_Map := Make_New;
begin
   qsort.sort (t);
   for I in t'Range loop
      Ada.Text_IO.Put_Line (Integer'Image (t (I)));
   end loop;

   if Contains_Key (m, 1) then
      Ada.Text_IO.Put_Line ("Is wrong");
   else
      Ada.Text_IO.Put_Line ("Is correct");
   end if;
   if Contains_Key (m, 0) then
      Ada.Text_IO.Put_Line ("Is wrong");
   else
      Ada.Text_IO.Put_Line ("Is correct");
   end if;

   Insert (m, 1, 100);
   Ada.Text_IO.Put_Line ("Inserted");
   if Get_Value (m, 1) = 100 then
      Ada.Text_IO.Put_Line ("Is correct");
   else
      Ada.Text_IO.Put_Line ("Is wrong");
   end if;

   Insert (m, 2, 200);
   Ada.Text_IO.Put_Line ("Inserted2");
   if Get_Value (m, 2) = 200 then
      Ada.Text_IO.Put_Line ("Is correct");
   else
      Ada.Text_IO.Put_Line ("Is wrong");
   end if;
   if Get_Value (m, 1) = 100 then
      Ada.Text_IO.Put_Line ("Is correct");
   else
      Ada.Text_IO.Put_Line ("Is wrong");
   end if;
   Delete_Key (m, 1);
   if Get_Value (m, 2) = 200 then
      Ada.Text_IO.Put_Line ("Is correct");
   else
      Ada.Text_IO.Put_Line ("Is wrong");
   end if;
   if Contains_Key (m, 1) then
      Ada.Text_IO.Put_Line ("Is wrong");
   else
      Ada.Text_IO.Put_Line ("Is correct");
   end if;

   --  test_pub_sub.Test_Pub_Sub;
   --  Test_Coroutine.Test_Coroutine;
   scheduler_demo.Run_Demo;
end Formalgorithms;
