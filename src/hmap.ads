generic
   type K is private;
   type V is private;
   Buckets : Natural;
   Bucket_Size : Natural;

   with function Default_Key return K;
   with function Default_Value return V;
   with function Hash_Key (Key : K) return Integer;
package hmap with SPARK_Mode is
   type Bucket_Idx is new Natural range 1 .. Buckets;

   type Node is record
      Key   : K;
      Value : V;
   end record;

   type Bucket_Data_Idx is new Natural range 1 .. Bucket_Size;
   type Bucket_Data_Size is new Natural range 0 .. Bucket_Size;
   type Bucket_Data is array (Bucket_Data_Idx) of Node;
   type Bucket is record
      Data : Bucket_Data;
      Size : Bucket_Data_Size;
   end record;

   type Hash_Map is array (Bucket_Idx) of Bucket;

   function Make_New return Hash_Map
   is ((others =>
          (Data => (others => (Key => Default_Key, Value => Default_Value)),
           Size => 0)));

   procedure Insert (HM : in out Hash_Map; Key : K; Value : V)
   with
     Pre  => not Contains_Key (HM, Key),
     Post => Contains_Key (HM, Key) and then Get_Value (HM, Key) = Value;

   function Get_Value (HM : Hash_Map; Key : K) return V
   with Pre => Contains_Key (HM, Key);

   function Contains_Key (HM : Hash_Map; Key : K) return Boolean
   with
     Post =>
       (if Contains_Key'Result
        then HM_Occ (HM, Key) = 1
        else HM_Occ (HM, Key) = 0);

   function HM_Occ_Def_Bucket (B : Bucket; Key : K) return Integer
   is (if B.Size = 0
       then 0
       elsif B.Data (Bucket_Data_Idx (B.Size)).Key = Key
       then 1 + HM_Occ_Def_Bucket ((Data => B.Data, Size => B.Size - 1), Key)
       else HM_Occ_Def_Bucket ((Data => B.Data, Size => B.Size - 1), Key))
   with Subprogram_Variant => (Decreases => B.Size);

   function Bucket_Key (Key : K) return Bucket_Idx
   is (Bucket_Idx (((Hash_Key (Key) mod Buckets) + Buckets) mod Buckets + 1));

   function HM_Occ (HM : Hash_Map; Key : K) return Integer
   is (HM_Occ_Def_Bucket (HM (Bucket_Key (Key)), Key));

private

end hmap;
