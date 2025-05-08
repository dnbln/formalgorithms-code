with hmap;

package hmap_int_to_int
  with SPARK_Mode
is
   type Hash_Map is private;
   function Contains_Key (HM : Hash_Map; Key : Integer) return Boolean;
   function Make_New return Hash_Map;
   function Get_Value (HM : Hash_Map; Key : Integer) return Integer;
   procedure Insert (HM : in out Hash_Map; Key : Integer; Value : Integer);

private
   function Integer_Identity (V : Integer) return Integer
   is (V);
   function Def_Integer return Integer
   is (0);

   package impl is new
     hmap
       (K             => Integer,
        V             => Integer,
        Buckets       => 1,
        Bucket_Size   => 1,
        Hash_Key      => Integer_Identity,
        Default_Key   => Def_Integer,
        Default_Value => Def_Integer);

   type Hash_Map is new impl.Hash_Map;
end hmap_int_to_int;
