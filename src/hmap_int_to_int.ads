with hmap;

package hmap_int_to_int
  with SPARK_Mode
is
   type Hash_Map is private;

   function All_Buckets_Have_Unique_Keys (HM : Hash_Map) return Boolean
   with Ghost;
   function Bucket_Key_Is_Full (HM : Hash_Map; Key : Integer) return Boolean;

   function Contains_Key (HM : Hash_Map; Key : Integer) return Boolean
   with Pre => All_Buckets_Have_Unique_Keys (HM);
   function Make_New return Hash_Map;
   function Get_Value (HM : Hash_Map; Key : Integer) return Integer
   with
     Pre => All_Buckets_Have_Unique_Keys (HM) and then Contains_Key (HM, Key);
   procedure Insert (HM : in out Hash_Map; Key : Integer; Value : Integer)
   with
     Pre =>
       All_Buckets_Have_Unique_Keys (HM)
       and then (if not Contains_Key (HM, Key)
                 then not Bucket_Key_Is_Full (HM, Key));
   procedure Delete_Key (HM : in out Hash_Map; Key : Integer)
   with
     Pre  => All_Buckets_Have_Unique_Keys (HM) and then Contains_Key (HM, Key),
     Post =>
       All_Buckets_Have_Unique_Keys (HM) and then (not Contains_Key (HM, Key));

private
   function Integer_Identity (V : Integer) return Integer
   is (V);
   function Def_Integer return Integer
   is (0);

   package impl is new
     hmap
       (K             => Integer,
        V             => Integer,
        Buckets       => 10,
        Bucket_Size   => 10,
        Hash_Key      => Integer_Identity,
        Default_Key   => Def_Integer,
        Default_Value => Def_Integer);

   type Hash_Map is new impl.Hash_Map;
end hmap_int_to_int;
