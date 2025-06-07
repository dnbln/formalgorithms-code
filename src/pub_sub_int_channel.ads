--  pragma Profile (Jorvik);

with pubsub;

package pub_sub_int_channel
  with SPARK_Mode
is
   function Default_Message return Integer;
   package impl is new
     pubsub
       (M               => Integer,
        Msg_Buffer_Size => 32,
        Default_Message => Default_Message);

   Ch : impl.Pub_Sub_Channel;
private
   function Default_Message return Integer
   is (0);
end pub_sub_int_channel;
