with Ada.Text_IO;

package body hmap
  with SPARK_Mode
is
   procedure Insert_Bucket (B : in out Bucket; Key : K; Value : V) is
   begin
      pragma Assert (Natural (B.Size) < Bucket_Size);
      B.Size := B.Size + 1;
      B.Data (Bucket_Data_Idx (B.Size)) := (Key => Key, Value => Value);
   end Insert_Bucket;

   procedure Insert (HM : in out Hash_Map; Key : K; Value : V) is
   begin
      Insert_Bucket (HM (Bucket_Key (Key)), Key, Value);
   end Insert;

   function Get_Value_Bucket (B : Bucket; Key : K) return V is
      Idx : Bucket_Data_Idx;
   begin
      if B.Size = 0 then
         pragma Assert (False);
      end if;

      Idx := Bucket_Data_Idx (B.Size);
      if B.Data (Idx).Key = Key then
         return B.Data (Idx).Value;
      end if;

      return Get_Value_Bucket ((Data => B.Data, Size => B.Size - 1), Key);
   end Get_Value_Bucket;

   function Get_Value (HM : Hash_Map; Key : K) return V
   is (Get_Value_Bucket (HM (Bucket_Key (Key)), Key));

   function Contains_Key_Bucket (B : Bucket; Key : K) return Boolean
   is (if B.Size = 0
       then False
       elsif B.Data (Bucket_Data_Idx (B.Size)).Key = Key
       then True
       else Contains_Key_Bucket ((Data => B.Data, Size => B.Size - 1), Key));

   function Contains_Key (HM : Hash_Map; Key : K) return Boolean
   is (Contains_Key_Bucket (HM (Bucket_Key (Key)), Key));

end hmap;
