package body pubsub
  with SPARK_Mode
is
   protected body Pub_Sub_Channel is
      procedure Publish (Message : M) is
         NewV : Version;
      begin
         if V < Version'Last then
            NewV := V + 1;
         else
            NewV := 0;
         end if;
         Msgs (Msg_Buffer_Index (NewV mod Version (Msg_Buffer_Size) + 1)) :=
           Message;
         V := NewV;
      end Publish;

      entry Subscribe_1 (Message : out M; Missed : out Natural)
        when Subs_1_V < V
      is
      begin
         Get_V (Message, Missed, Subs_1_V);
      end Subscribe_1;

      entry Subscribe_2 (Message : out M; Missed : out Natural)
        when Subs_2_V < V
      is
      begin
         Get_V (Message, Missed, Subs_2_V);
      end Subscribe_2;

      procedure Get_V
        (Message : out M; Missed : out Natural; Sub_V : in out Version)
      is
         New_Sub_V : Version := Sub_V + 1;
         Temp_V    : Version;
      begin
         if V > Version (Msg_Buffer_Size)
           and then New_Sub_V < V - Version (Msg_Buffer_Size)
         then
            Temp_V := V - Version (Msg_Buffer_Size) + 1;
            Missed := Natural (Temp_V - New_Sub_V);
            New_Sub_V := Temp_V;
         else
            Missed := 0;
         end if;
         Message :=
           Msgs
             (Msg_Buffer_Index (New_Sub_V mod Version (Msg_Buffer_Size) + 1));
         Sub_V := New_Sub_V;
      end Get_V;
   end Pub_Sub_Channel;
end pubsub;
