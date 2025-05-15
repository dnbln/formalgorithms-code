with Ada.Text_IO;

package body test_pub_sub
  with SPARK_Mode
is

   task body Tx is
   begin
      loop
         for I in 1 .. 100 loop
            pub_sub_int_channel.Ch.Publish (I);
            delay 0.1;
         end loop;
      end loop;
   end Tx;

   task body Rx is
      Msg    : Integer;
      Missed : Natural;
   begin
      loop
         pub_sub_int_channel.Ch.Subscribe_2 (Msg, Missed);
         Ada.Text_IO.Put_Line ("[rx] Got message: " & Integer'Image (Msg));
         if Missed /= 0 then
            Ada.Text_IO.Put_Line
              ("[rx] Missed " & Integer'Image (Missed) & " messages");
         end if;
      end loop;
   end Rx;

   procedure Test_Pub_Sub is
      Msg    : Integer;
      Missed : Natural;
   begin
      loop
         pub_sub_int_channel.Ch.Subscribe_1 (Msg, Missed);

         Ada.Text_IO.Put_Line ("[main] Got message: " & Integer'Image (Msg));
         if Missed /= 0 then
            Ada.Text_IO.Put_Line
              ("[main] Missed " & Integer'Image (Missed) & " messages");
         end if;
      end loop;
   end Test_Pub_Sub;

end test_pub_sub;
