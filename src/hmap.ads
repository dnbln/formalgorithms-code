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

   Bucket_Size_Max : constant Bucket_Data_Size :=
     Bucket_Data_Size (Bucket_Size);

   type Bucket_Data is array (Bucket_Data_Idx) of Node;
   type Bucket is record
      Data : Bucket_Data;
      Size : Bucket_Data_Size;
   end record;

   function Contains_Key_Bucket_Index
     (B : Bucket; Key : K) return Bucket_Data_Size
   is (if B.Size = 0
       then 0
       elsif B.Data (Bucket_Data_Idx (B.Size)).Key = Key
       then B.Size
       else
         Contains_Key_Bucket_Index ((Data => B.Data, Size => B.Size - 1), Key))
   with
     Subprogram_Variant => (Decreases => B.Size),
     Pre                => Unique_Keys (B),
     Post               =>
       Contains_Key_Bucket_Index'Result <= B'Size
       and then (if B.Size > 0
                 then
                   (if Contains_Key_Bucket_Index'Result > 0
                    then
                      B.Data
                        (Bucket_Data_Idx (Contains_Key_Bucket_Index'Result))
                        .Key
                      = Key
                      and then (for all P
                                  in Bucket_Data_Idx'First
                                     .. Bucket_Data_Idx (B.Size)
                                => (if P
                                      /= Bucket_Data_Idx
                                           (Contains_Key_Bucket_Index'Result)
                                    then B.Data (P).Key /= Key))
                    else
                      (for all P
                         in Bucket_Data_Idx'First .. Bucket_Data_Idx (B.Size)
                       => B.Data (P).Key /= Key)));

   function Contains_Key_Bucket (B : Bucket; Key : K) return Boolean
   is (Contains_Key_Bucket_Index (B, Key) /= 0)
   with
     Pre  => Unique_Keys (B),
     Post =>
       (if B.Size > 0
        then
          (if Contains_Key_Bucket'Result
           then
             (for some P in Bucket_Data_Idx'First .. Bucket_Data_Idx (B.Size)
              => B.Data (P).Key = Key)
           else
             (for all P in Bucket_Data_Idx'First .. Bucket_Data_Idx (B.Size)
              => B.Data (P).Key /= Key)));

   function Unique_Keys (B : Bucket) return Boolean
   is (if B.Size = 0
       then True
       else
         (for all I in Bucket_Data_Idx'First .. Bucket_Data_Idx (B.Size)
          => (for all J in Bucket_Data_Idx'First .. I - 1
              => (B.Data (I).Key /= B.Data (J).Key))))
   with Ghost;

   type Hash_Map is array (Bucket_Idx) of Bucket;

   function All_Buckets_Have_Unique_Keys (HM : Hash_Map) return Boolean
   is (for all I in HM'Range => Unique_Keys (HM (I)))
   with Ghost;

   function Make_New return Hash_Map
   is ((others =>
          (Data => (others => (Key => Default_Key, Value => Default_Value)),
           Size => 0)));

   function Bucket_Key (Key : K) return Bucket_Idx
   is (Bucket_Idx (((Hash_Key (Key) mod Buckets) + Buckets) mod Buckets + 1));

   function Bucket_Is_Full (B : Bucket) return Boolean
   is (B.Size = Bucket_Size_Max)
   with
     Pre  => B.Size <= Bucket_Size_Max,
     Post =>
       (if Bucket_Is_Full'Result
        then B.Size = Bucket_Size_Max
        else B.Size < Bucket_Size_Max);

   function Bucket_Key_Is_Full (HM : Hash_Map; Key : K) return Boolean
   is (Bucket_Is_Full (HM (Bucket_Key (Key))));

   function Get_Node_Bucket (B : Bucket; Key : K) return Node
   with
     Pre  =>
       Unique_Keys (B)
       and then Contains_Key_Bucket (B, Key)
       and then Unique_Keys (B),
     Post =>
       Get_Node_Bucket'Result.Key = Key
       and then Get_Node_Bucket'Result
                = B.Data
                    (Bucket_Data_Idx (Contains_Key_Bucket_Index (B, Key)));

   procedure Insert (HM : in out Hash_Map; Key : K; Value : V)
   with
     Pre  =>
       All_Buckets_Have_Unique_Keys (HM)
       and then (if not Contains_Key (HM, Key)
                 then not Bucket_Key_Is_Full (HM, Key)),
     Post =>
       All_Buckets_Have_Unique_Keys (HM)
       and then Contains_Key (HM, Key)
       and then Get_Value (HM, Key) = Value
       and then No_Changes_Other_Than_To_Key (HM, HM'Old, Key);

   function No_Changes_Other_Than_To_Key_Bucket
     (B, BOld : Bucket; Key : K) return Boolean
   is ((B.Size = BOld.Size + 1 or else B.Size = BOld.Size)
       and then (if B.Size > 0
                 then
                   (for all BIdx
                      in Bucket_Data_Idx'First .. Bucket_Data_Idx (B.Size)
                    => (if B.Data (BIdx).Key /= Key
                        then
                          Contains_Key_Bucket (BOld, B.Data (BIdx).Key)
                          and then Get_Node_Bucket (BOld, B.Data (BIdx).Key)
                                   = B.Data (BIdx)))))
   with Ghost, Pre => Unique_Keys (BOld) and then Unique_Keys (B);

   function No_Changes_Other_Than_To_Key
     (HM, HMOld : Hash_Map; Key : K) return Boolean
   is (for all BIdx in Bucket_Idx'Range
       => No_Changes_Other_Than_To_Key_Bucket (HM (BIdx), HMOld (BIdx), Key))
   with
     Ghost,
     Pre =>
       All_Buckets_Have_Unique_Keys (HM)
       and then All_Buckets_Have_Unique_Keys (HMOld);

   procedure Lemma_No_Changes_Other_Than_To_Key_Eq (A, B : Bucket; Key : K)
   with
     Ghost,
     Pre  => A = B and then Unique_Keys (A),
     Post => No_Changes_Other_Than_To_Key_Bucket (A, B, Key);

   procedure Delete_Key (HM : in out Hash_Map; Key : K)
   with
     Pre  => All_Buckets_Have_Unique_Keys (HM) and then Contains_Key (HM, Key),
     Post =>
       All_Buckets_Have_Unique_Keys (HM)
       and then (not Contains_Key (HM, Key))
       and then No_Changes_Other_Than_To_Key (HM'Old, HM, Key);

   function Get_Value (HM : Hash_Map; Key : K) return V
   with
     Pre => All_Buckets_Have_Unique_Keys (HM) and then Contains_Key (HM, Key);

   function Contains_Key (HM : Hash_Map; Key : K) return Boolean
   with Pre => All_Buckets_Have_Unique_Keys (HM);

   function HM_Occ_Def_Bucket (B : Bucket; Key : K) return Bucket_Data_Size
   is (if B.Size = 0
       then 0
       elsif B.Data (Bucket_Data_Idx (B.Size)).Key = Key
       then 1 + HM_Occ_Def_Bucket ((Data => B.Data, Size => B.Size - 1), Key)
       else HM_Occ_Def_Bucket ((Data => B.Data, Size => B.Size - 1), Key))
   with
     Post               => HM_Occ_Def_Bucket'Result <= B.Size,
     Subprogram_Variant => (Decreases => B.Size);

   function HM_Occ (HM : Hash_Map; Key : K) return Bucket_Data_Size
   is (HM_Occ_Def_Bucket (HM (Bucket_Key (Key)), Key));

private

end hmap;
