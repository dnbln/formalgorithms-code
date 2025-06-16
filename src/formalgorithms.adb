pragma Partition_Elaboration_Policy (Concurrent);
--  with qsort;
with Ada.Text_IO;
--  with Test_Coroutine;
--  pragma Elaborate_All (Test_Coroutine);
--  with Types;
--  with hmap_int_to_int; use hmap_int_to_int;
--  with pub_sub_int_channel;
--  with test_pub_sub;
with Scheduler;

with Scheduler_Demo_Timers;
with scheduler_demo_files;
with Scheduler_Demo_Sockets;

pragma Elaborate_All (Scheduler);

procedure Formalgorithms is
   --  t : Types.IArr := (0, 10, 45, 1, -10, -100);
   --  m : Hash_Map := Make_New;
begin
   --  qsort.sort (t);
   --  for I in t'Range loop
   --     Ada.Text_IO.Put_Line (Integer'Image (t (I)));
   --  end loop;

   --  if Contains_Key (m, 1) then
   --     Ada.Text_IO.Put_Line ("Is wrong");
   --  else
   --     Ada.Text_IO.Put_Line ("Is correct");
   --  end if;
   --  if Contains_Key (m, 0) then
   --     Ada.Text_IO.Put_Line ("Is wrong");
   --  else
   --     Ada.Text_IO.Put_Line ("Is correct");
   --  end if;

   --  Insert (m, 1, 100);
   --  Ada.Text_IO.Put_Line ("Inserted");
   --  if Get_Value (m, 1) = 100 then
   --     Ada.Text_IO.Put_Line ("Is correct");
   --  else
   --     Ada.Text_IO.Put_Line ("Is wrong");
   --  end if;

   --  Insert (m, 2, 200);
   --  Ada.Text_IO.Put_Line ("Inserted2");
   --  if Get_Value (m, 2) = 200 then
   --     Ada.Text_IO.Put_Line ("Is correct");
   --  else
   --     Ada.Text_IO.Put_Line ("Is wrong");
   --  end if;
   --  if Get_Value (m, 1) = 100 then
   --     Ada.Text_IO.Put_Line ("Is correct");
   --  else
   --     Ada.Text_IO.Put_Line ("Is wrong");
   --  end if;
   --  Delete_Key (m, 1);
   --  if Get_Value (m, 2) = 200 then
   --     Ada.Text_IO.Put_Line ("Is correct");
   --  else
   --     Ada.Text_IO.Put_Line ("Is wrong");
   --  end if;
   --  if Contains_Key (m, 1) then
   --     Ada.Text_IO.Put_Line ("Is wrong");
   --  else
   --     Ada.Text_IO.Put_Line ("Is correct");
   --  end if;

   --  test_pub_sub.Test_Pub_Sub;
   --  Test_Coroutine.Test_Coroutine;
   --  Scheduler_Demo_Timers.Run_Demo;
   Scheduler_Demo_Sockets.Run_Demo;
end Formalgorithms;
