with qsort;
with Ada.Text_IO;
with Types;

procedure Formalgorithms is
   t: types.IArr := (0, 10, 45, 1, -10, -100);
begin
   qsort.sort(t);
   for I in t'Range loop
      Ada.Text_IO.Put_Line(Integer'Image(t(I)));
   end loop;

end Formalgorithms;