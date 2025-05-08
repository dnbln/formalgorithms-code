with qsort;
with Ada.Text_IO;
with Types;
with hmap_int_to_int; use hmap_int_to_int;

procedure Formalgorithms is
   t : types.IArr := (0, 10, 45, 1, -10, -100);
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
end Formalgorithms;
