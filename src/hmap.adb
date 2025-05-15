package body hmap
  with SPARK_Mode
is
   function Contains_Key (HM : Hash_Map; Key : K) return Boolean
   is (Contains_Key_Bucket (HM (Bucket_Key (Key)), Key));

   function Get_Node_Bucket (B : Bucket; Key : K) return Node is
      Idx : constant Bucket_Data_Size := Contains_Key_Bucket_Index (B, Key);
   begin
      pragma Assert (Idx > 0);
      return B.Data (Bucket_Data_Idx (Idx));
   end Get_Node_Bucket;

   function Get_Value_Bucket (B : Bucket; Key : K) return V
   is (Get_Node_Bucket (B, Key).Value)
   with Pre => Unique_Keys (B) and then Contains_Key_Bucket (B, Key);

   procedure Other_Buckets_Unchanged
     (HM, HMOld : Hash_Map; Changed : Bucket_Idx; Key : K)
   with
     Ghost,
     Pre  =>
       HM (Bucket_Idx'First .. Changed - 1)
       = HMOld (Bucket_Idx'First .. Changed - 1)
       and then HM (Changed + 1 .. Bucket_Idx'Last)
                = HMOld (Changed + 1 .. Bucket_Idx'Last)
       and then Unique_Keys (HM (Changed))
       and then Unique_Keys (HMOld (Changed))
       and then All_Buckets_Have_Unique_Keys (HM)
       and then All_Buckets_Have_Unique_Keys (HMOld)
       and then No_Changes_Other_Than_To_Key_Bucket
                  (HM (Changed), HMOld (Changed), Key),
     Post => No_Changes_Other_Than_To_Key (HM, HMOld, Key)
   is
   begin
      if Changed > Bucket_Idx'First then
         Lemma_No_Changes_Other_Than_To_Key_Eq
           (HM (Bucket_Idx'First), HMOld (Bucket_Idx'First), Key);
         for I in Bucket_Idx'First + 1 .. Changed - 1 loop
            pragma
              Loop_Invariant
                (for all J in Bucket_Idx'First .. I - 1
                 => No_Changes_Other_Than_To_Key_Bucket
                      (HM (J), HMOld (J), Key));
            Lemma_No_Changes_Other_Than_To_Key_Eq (HM (I), HMOld (I), Key);
         end loop;
      end if;
      pragma
        Assert
          (for all J in Bucket_Idx'First .. Changed
           => No_Changes_Other_Than_To_Key_Bucket (HM (J), HMOld (J), Key));

      if Changed < Bucket_Idx'Last then
         for I in Changed + 1 .. Bucket_Idx'Last loop
            pragma
              Loop_Invariant
                (for all J in Bucket_Idx'First .. I - 1
                 => No_Changes_Other_Than_To_Key_Bucket
                      (HM (J), HMOld (J), Key));
            Lemma_No_Changes_Other_Than_To_Key_Eq (HM (I), HMOld (I), Key);
         end loop;
      end if;
      pragma
        Assert
          (for all J in Bucket_Idx'Range
           => No_Changes_Other_Than_To_Key_Bucket (HM (J), HMOld (J), Key));

   end Other_Buckets_Unchanged;

   procedure Lemma_If_Is_In_Bucket_Then_Get_Value_Returns_It
     (B : Bucket; P : Bucket_Data_Idx; Key : K; Value : V)
   with
     Ghost,
     Pre  =>
       B.Size > 0
       and then P <= Bucket_Data_Idx (B.Size)
       and then B.Data (P) = (Key => Key, Value => Value)
       and then Unique_Keys (B)
       and then Contains_Key_Bucket_Index (B, Key) = Bucket_Data_Size (P),
     Post => Get_Value_Bucket (B, Key) = Value
   is
   begin
      pragma Assert (Get_Node_Bucket (B, Key) = B.Data (P));
   end Lemma_If_Is_In_Bucket_Then_Get_Value_Returns_It;

   procedure Do_Insert_Into_Bucket (B : in out Bucket; Key : K; Value : V)
   with
     Pre  =>
       Unique_Keys (B)
       and then (not Contains_Key_Bucket (B, Key))
       and then (not Bucket_Is_Full (B)),
     Post =>
       (B.Size = B'Old.Size + 1
        and then B.Size > 0
        and then (if B'Old.Size > 0
                  then
                    B.Data (1 .. Bucket_Data_Idx (B'Old.Size))
                    = B'Old.Data (1 .. Bucket_Data_Idx (B'Old.Size)))
        and then B.Data (Bucket_Data_Idx (B.Size))
                 = (Key => Key, Value => Value))
       and then Get_Value_Bucket (B, Key) = Value
       and then Unique_Keys (B)
       and then No_Changes_Other_Than_To_Key_Bucket (B, B'Old, Key)
       and then No_Changes_Other_Than_To_Key_Bucket (B'Old, B, Key)
   is
   begin
      B.Size := B.Size + 1;
      B.Data (Bucket_Data_Idx (B.Size)) := (Key => Key, Value => Value);
      pragma Assert (Contains_Key_Bucket (B, Key));
      Lemma_If_Is_In_Bucket_Then_Get_Value_Returns_It
        (B, Bucket_Data_Idx (B.Size), Key, Value);
      pragma Assert (Get_Value_Bucket (B, Key) = Value);
   end Do_Insert_Into_Bucket;

   procedure Replace_In_Bucket
     (B : in out Bucket; P : Bucket_Data_Idx; Key : K; Value : V)
   with
     Pre  =>
       Unique_Keys (B)
       and then Contains_Key_Bucket_Index (B, Key) = Bucket_Data_Size (P)
       and then P <= Bucket_Data_Idx (B.Size)
       and then B.Data (P).Key = Key,
     Post =>
       B.Size = B'Old.Size
       and then Unique_Keys (B)
       and then B.Data (Bucket_Data_Idx'First .. P - 1)
                = B'Old.Data (Bucket_Data_Idx'First .. P - 1)
       and then B.Data (P + 1 .. Bucket_Data_Idx'Last)
                = B'Old.Data (P + 1 .. Bucket_Data_Idx'Last)
       and then Contains_Key_Bucket (B, Key)
       and then Get_Value_Bucket (B, Key) = Value
       and then No_Changes_Other_Than_To_Key_Bucket (B, B'Old, Key)
       and then No_Changes_Other_Than_To_Key_Bucket (B'Old, B, Key)
   is
      BOld : constant Bucket := B
      with Ghost;
   begin
      B.Data (P).Value := Value;
      pragma Assert (B.Data (P).Key = BOld.Data (P).Key);
      pragma Assert (B.Data (P).Key = Key);
      pragma Assert (Unique_Keys (B));
      pragma Assert (Unique_Keys (BOld));
      Lemma_If_Is_In_Bucket_Then_Get_Value_Returns_It (B, P, Key, Value);
      pragma
        Assert
          (for all I in Bucket_Data_Idx'First .. Bucket_Data_Idx (B.Size)
           => (if I /= P then B.Data (I).Key /= Key));
      pragma
        Assert
          (for all I in Bucket_Data_Idx'First .. Bucket_Data_Idx (B.Size)
           => (if I /= P
               then
                 Contains_Key_Bucket_Index (BOld, B.Data (I).Key)
                 = Bucket_Data_Size (I)));
      pragma
        Assert
          (for all I in Bucket_Data_Idx'First .. Bucket_Data_Idx (B.Size)
           => (if I /= P
               then Get_Node_Bucket (BOld, B.Data (I).Key) = BOld.Data (I)));
      pragma
        Assert
          (for all I in Bucket_Data_Idx'First .. Bucket_Data_Idx (B.Size)
           => (if I /= P
               then Get_Node_Bucket (BOld, B.Data (I).Key) = B.Data (I)));
   end Replace_In_Bucket;

   procedure Insert_Bucket (B : in out Bucket; Key : K; Value : V)
   with
     Pre  =>
       Unique_Keys (B)
       and then (if not Contains_Key_Bucket (B, Key)
                 then not Bucket_Is_Full (B)),
     Post =>
       Contains_Key_Bucket (B, Key)
       and then Get_Value_Bucket (B, Key) = Value
       and then Unique_Keys (B)
       and then (if Contains_Key_Bucket (B'Old, Key)
                 then B.Size = B'Old.Size
                 else B.Size = B'Old.Size + 1)
       and then No_Changes_Other_Than_To_Key_Bucket (B, B'Old, Key)
       and then No_Changes_Other_Than_To_Key_Bucket (B'Old, B, Key)
   is
      P    : constant Bucket_Data_Size := Contains_Key_Bucket_Index (B, Key);
      BOld : constant Bucket := B
      with Ghost;
   begin
      if P = 0 then
         Do_Insert_Into_Bucket (B, Key, Value);
         pragma Assert (Contains_Key_Bucket (B, Key));
         pragma Assert (Get_Value_Bucket (B, Key) = Value);
         pragma Assert (No_Changes_Other_Than_To_Key_Bucket (B, BOld, Key));
      else
         pragma Assert (P > 0);
         Replace_In_Bucket (B, Bucket_Data_Idx (P), Key, Value);
         pragma Assert (Contains_Key_Bucket (B, Key));
         pragma Assert (Get_Value_Bucket (B, Key) = Value);
         pragma Assert (No_Changes_Other_Than_To_Key_Bucket (B, BOld, Key));
      end if;
   end Insert_Bucket;

   procedure Insert (HM : in out Hash_Map; Key : K; Value : V) is
      HMOld : constant Hash_Map := HM
      with Ghost;
      BId   : constant Bucket_Idx := Bucket_Key (Key);
      B     : Bucket renames HM (BId);
   begin
      Insert_Bucket (B, Key, Value);
      pragma Assert (Unique_Keys (B));
      Other_Buckets_Unchanged (HM, HMOld, BId, Key);
   end Insert;

   procedure Lemma_No_Changes_Other_Than_To_Key_Eq (A, B : Bucket; Key : K) is
   begin
      null;
   end Lemma_No_Changes_Other_Than_To_Key_Eq;

   procedure Lemma_Key_Set_Minus
     (A, B : Bucket; Partition : Bucket_Data_Idx; Key : K)
   with
     Ghost,
     Pre  =>
       Bucket_Data_Size (Partition) <= B.Size
       and then A.Data (Partition).Key = Key
       and then Unique_Keys (A)
       and then Unique_Keys (B)
       and then A.Size = B.Size + 1
       and then (if Partition > 0
                 then
                   (for all I in Bucket_Data_Idx'First .. Partition - 1
                    => A.Data (I) = B.Data (I)))
       and then (if B.Size > 0
                 then
                   (for all I in Partition .. Bucket_Data_Idx (B.Size)
                    => A.Data (I + 1) = B.Data (I))),
     Post =>
       (not Contains_Key_Bucket (B, Key))
       and then No_Changes_Other_Than_To_Key_Bucket (B, A, Key)
   is
   begin
      pragma
        Assert
          (((for all BIdx in Bucket_Data_Idx'First .. Bucket_Data_Idx (A.Size)
             => (if BIdx /= Partition then A.Data (BIdx).Key /= Key))));
      pragma
        Assert
          (((for all BIdx in Bucket_Data_Idx'First .. Bucket_Data_Idx (A.Size)
             => (if A.Data (BIdx).Key = Key then BIdx = Partition))));
      pragma
        Assert
          (((for all BIdx in Bucket_Data_Idx'First .. Bucket_Data_Idx (A.Size)
             => (if A.Data (BIdx).Key /= Key
                 then
                   Contains_Key_Bucket (B, A.Data (BIdx).Key)
                   and then (if BIdx < Partition
                             then
                               Get_Node_Bucket (B, A.Data (BIdx).Key)
                               = B.Data (BIdx)
                             else
                               Get_Node_Bucket (B, A.Data (BIdx).Key)
                               = B.Data (BIdx - 1))))));
      pragma
        Assert
          (((for all BIdx in Bucket_Data_Idx'First .. Bucket_Data_Idx (A.Size)
             => (if A.Data (BIdx).Key /= Key
                 then
                   Contains_Key_Bucket (B, A.Data (BIdx).Key)
                   and then Get_Node_Bucket (B, A.Data (BIdx).Key)
                            = A.Data (BIdx)))));
   end Lemma_Key_Set_Minus;

   procedure Lemma_Delete_Keeps_Uniqueness
     (BOld, B : Bucket; P : Bucket_Data_Idx)
   with
     Ghost,
     Pre  =>
       BOld.Size = B.Size + 1
       and then Unique_Keys (BOld)
       and then (if P > 0
                 then
                   (for all I in Bucket_Data_Idx'First .. P - 1
                    => BOld.Data (I) = B.Data (I)))
       and then (if B.Size > 0
                 then
                   (for all I in P .. Bucket_Data_Idx (B.Size)
                    => BOld.Data (I + 1) = B.Data (I))),
     Post => Unique_Keys (B)
   is
   begin
      if not Unique_Keys (B) then
         pragma
           Assert
             (for some I in Bucket_Data_Idx'First .. Bucket_Data_Idx (B.Size)
              => (for some J in Bucket_Data_Idx'First .. I - 1
                  => (B.Data (I).Key = B.Data (J).Key)));
         pragma
           Assert
             (for some I in Bucket_Data_Idx'First .. Bucket_Data_Idx (B.Size)
              => (for some J in Bucket_Data_Idx'First .. I - 1
                  => (if I < P
                      then (BOld.Data (J).Key = BOld.Data (I).Key)
                      elsif J < P
                      then (BOld.Data (J).Key = BOld.Data (I + 1).Key)
                      else (BOld.Data (J + 1).Key = BOld.Data (I + 1).Key))));
         pragma Assert (not Unique_Keys (BOld));
         pragma Assert (False);
      end if;
   end Lemma_Delete_Keeps_Uniqueness;

   procedure Delete_Key_Bucket (B : in out Bucket; Key : K)
   with
     Pre  => Unique_Keys (B) and then Contains_Key_Bucket (B, Key),
     Post =>
       Unique_Keys (B)
       and then (not Contains_Key_Bucket (B, Key))
       and then B.Size = B'Old.Size - 1
       and then No_Changes_Other_Than_To_Key_Bucket (B, B'Old, Key)
       and then No_Changes_Other_Than_To_Key_Bucket (B'Old, B, Key)
   is
      P    : constant Bucket_Data_Size := Contains_Key_Bucket_Index (B, Key);
      BOld : constant Bucket := B
      with Ghost;
   begin
      pragma Assert (P > 0);
      pragma Assert (Unique_Keys (BOld));
      if P = B.Size then
         B.Size := B.Size - 1;
         pragma Assert (Unique_Keys (B));
         pragma Assert (No_Changes_Other_Than_To_Key_Bucket (B, BOld, Key));
      elsif B.Size > 1 then
         pragma Assert (Unique_Keys (B));
         if P > 1 then
            for I in Bucket_Data_Idx (P) .. Bucket_Data_Idx (B.Size - 1) loop
               pragma
                 Loop_Invariant
                   (BOld.Data
                      (Bucket_Data_Idx'First .. Bucket_Data_Idx (P - 1))
                      = B.Data
                          (Bucket_Data_Idx'First .. Bucket_Data_Idx (P - 1)));
               pragma
                 Loop_Invariant
                   (for all J in Bucket_Data_Idx (P) .. I - 1
                    => BOld.Data (J + 1) = B.Data (J));
               B.Data (I) := B.Data (I + 1);
            end loop;
            B.Size := B.Size - 1;
            pragma
              Assert
                (for all J in Bucket_Data_Idx'First .. Bucket_Data_Idx (P - 1)
                 => B.Data (J) = BOld.Data (J));
            pragma
              Assert
                (for all J in Bucket_Data_Idx (P) .. Bucket_Data_Idx (B.Size)
                 => B.Data (J) = BOld.Data (J + 1));

            Lemma_Delete_Keeps_Uniqueness (BOld, B, Bucket_Data_Idx (P));

            pragma Assert (Unique_Keys (B));
            pragma
              Assert
                (for all I in Bucket_Data_Idx (P) .. Bucket_Data_Idx (B.Size)
                 => BOld.Data (I + 1) = B.Data (I));
            Lemma_Key_Set_Minus (BOld, B, Bucket_Data_Idx (P), Key);
            pragma Assert (No_Changes_Other_Than_To_Key_Bucket (B, BOld, Key));
         else
            pragma Assert (P = 1);

            for I in Bucket_Data_Idx (P) .. Bucket_Data_Idx (B.Size - 1) loop
               pragma
                 Loop_Invariant
                   (for all J in Bucket_Data_Idx (P) .. I - 1
                    => BOld.Data (J + 1) = B.Data (J));
               B.Data (I) := B.Data (I + 1);
            end loop;
            B.Size := B.Size - 1;
            pragma
              Assert
                (for all J in Bucket_Data_Idx (P) .. Bucket_Data_Idx (B.Size)
                 => B.Data (J) = BOld.Data (J + 1));

            Lemma_Delete_Keeps_Uniqueness (BOld, B, Bucket_Data_Idx (P));

            pragma Assert (Unique_Keys (B));
            pragma
              Assert
                (for all I in Bucket_Data_Idx (P) .. Bucket_Data_Idx (B.Size)
                 => BOld.Data (I + 1) = B.Data (I));
            Lemma_Key_Set_Minus (BOld, B, Bucket_Data_Idx (P), Key);
            pragma Assert (No_Changes_Other_Than_To_Key_Bucket (B, BOld, Key));
         end if;
      elsif B.Size = 1 then
         B.Size := B.Size - 1;
         pragma Assert (Unique_Keys (B));
         pragma Assert (No_Changes_Other_Than_To_Key_Bucket (B, BOld, Key));
      end if;
   end Delete_Key_Bucket;

   procedure Delete_Key (HM : in out Hash_Map; Key : K) is
      BId   : constant Bucket_Idx := Bucket_Key (Key);
      HMOld : constant Hash_Map := HM
      with Ghost;
      B     : Bucket renames HM (BId);
   begin
      Delete_Key_Bucket (B, Key);
      pragma Assert (Unique_Keys (B));
      Other_Buckets_Unchanged (HM, HMOld, BId, Key);
   end Delete_Key;

   function Get_Value (HM : Hash_Map; Key : K) return V
   is (Get_Value_Bucket (HM (Bucket_Key (Key)), Key));

end hmap;
