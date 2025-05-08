package body hmap_int_to_int
  with SPARK_Mode
is
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
end hmap_int_to_int;
