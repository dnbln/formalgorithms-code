with pub_sub_int_channel;

package test_pub_sub
  with SPARK_Mode
is

   task Tx;
   task Rx;

   procedure Test_Pub_Sub;

end test_pub_sub;
