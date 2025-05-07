with insort;
with Ada.Text_IO;

procedure Hello is
   t : insort.Arr := (0, 10, 45, 1, -10, -100);
begin
   insort.sort (t);
   for I in t'Range loop
      Ada.Text_IO.Put_Line (Integer'Image (t (I)));
   end loop;

end Hello;
