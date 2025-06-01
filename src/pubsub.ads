generic
   type M is private;
   Msg_Buffer_Size : Positive;

   with function Default_Message return M;
package pubsub with SPARK_Mode is
   type Version is new Natural;
   type Msg_Buffer_Index is new Natural range 1 .. Msg_Buffer_Size;
   type Msg_Buffer_Array is array (Msg_Buffer_Index) of M;

   protected type Pub_Sub_Channel is
      procedure Publish (Message : M);
      entry Subscribe_1 (Message : out M; Missed : out Natural);
      entry Subscribe_2 (Message : out M; Missed : out Natural);
   private
      procedure Get_V
        (Message : out M; Missed : out Natural; Sub_V : in out Version)
      with Pre => Sub_V < Version'Last;
      procedure Clear;

      Msgs     : Msg_Buffer_Array := (others => Default_Message);
      Subs_1_V : Version := 0;
      Subs_2_V : Version := 0;
      V        : Version := 0;
   end Pub_Sub_Channel;

private
end pubsub;
