package body hmap_int_to_int
  with SPARK_Mode
is
   overriding
   function All_Buckets_Have_Unique_Keys (HM : Hash_Map) return Boolean
   is (impl.All_Buckets_Have_Unique_Keys (impl.Hash_Map (HM)));
   overriding
   function Bucket_Key_Is_Full (HM : Hash_Map; Key : Integer) return Boolean
   is (impl.Bucket_Key_Is_Full (impl.Hash_Map (HM), Key));
   overriding
   function Contains_Key (HM : Hash_Map; Key : Integer) return Boolean
   is (impl.Contains_Key (impl.Hash_Map (HM), Key));
   overriding
   function Make_New return Hash_Map
   is (Hash_Map (impl.Make_New));
   overriding
   function Get_Value (HM : Hash_Map; Key : Integer) return Integer
   is (impl.Get_Value (impl.Hash_Map (HM), Key));
   overriding
   procedure Insert (HM : in out Hash_Map; Key : Integer; Value : Integer) is
   begin
      impl.Insert (impl.Hash_Map (HM), Key, Value);
   end Insert;
   overriding
   procedure Delete_Key (HM : in out Hash_Map; Key : Integer) is
   begin
      impl.Delete_Key (impl.Hash_Map (HM), Key);
   end Delete_Key;
end hmap_int_to_int;
