with Ada.Text_IO;   use Ada.Text_IO;
with Lemmas.Sorted; use Lemmas.Sorted;

package body qsort
  with SPARK_Mode
is
   procedure Swap_Array (A : in out IArr; J : Natural; K : Natural)
   with
     Pre  =>
       A'Last < Integer'Last
       and then A'Length < Integer'Last
       and then A'Length >= 1
       and then J in A'Range
       and then K in A'Range,
     Post =>
       A'Old (J) = A (K)
       and then A'Old (K) = A (J)
       and then (for all L in A'Old'Range
                 => (if J /= L and then K /= L then A'Old (L) = A (L)))
       and then Multiset_Unchanged (A'Old, A)
   is
      A_Init : IArr (A'Range) := A;
      Temp   : Integer := A (J);

      -- ghost variable

      A_After_First : IArr (A'Range)
      with Ghost;

      -- ghost procedure

      procedure Prove_Perm
      with
        Ghost,
        Pre  =>
          J in A'Range
          and then A'Last < Integer'Last
          and then A'Length < Integer'Last
          and then K in A'Range
          and then Is_Set (A_Init, J, A_Init (K), A_After_First)
          and then Is_Set (A_After_First, K, A_Init (J), A),
        Post => Multiset_Unchanged (A_Init, A)
      is
      begin
         for V in Integer loop
            Occ_Set (A_Init, A_After_First, J, A_Init (K), V);
            Occ_Set (A_After_First, A, K, A_Init (J), V);
            pragma
              Loop_Invariant
                (for all F in Integer'First .. V
                 => Occ (A_Init, F) = Occ (A, F));
         end loop;
      end Prove_Perm;

   begin
      A (J) := A (K);
      A_After_First := A; -- ghost code

      pragma Assert (Is_Set (A_Init, J, A_Init (K), A_After_First));

      A (K) := Temp;

      pragma Assert (Is_Set (A_After_First, K, A_Init (J), A));
      Prove_Perm; -- ghost code

   end Swap_Array;

   procedure Multiset_Split_Sort (A : in out IArr; I : Natural)
   with
     Pre  =>
       A'Last < Integer'Last - 1
       and then A'Length > 0
       and then A'Length < Integer'Last

       and then I >= A'First
       and then I <= A'Last
       and then I + 1 < Integer'Last
       and then (for all P in A'First .. I - 1 => A (P) <= A (I))
       and then (for all P in I + 1 .. A'Last => A (P) > A (I)),
     Post => Weak_Sorted (A) and then Multiset_Unchanged (A, A'Old)
   is
      AOld      : constant IArr (A'Range) := A
      with Ghost;
      ALeft     : IArr (A'First .. I - 1) := A (A'First .. I - 1);
      ALeftOld  : constant IArr := ALeft
      with Ghost;
      ARight    : IArr (I + 1 .. A'Last) := A (I + 1 .. A'Last);
      ARightOld : constant IArr := ARight
      with Ghost;

      procedure Lemma1A (A : IArr; Start : Integer)
      with
        Ghost,
        Pre  =>
          A'Last < Integer'Last
          and then A'Length < Integer'Last
          and then (for all V in Start .. Integer'Last
                    => not Has_Value (A, V)),
        Post => (for all V in Start .. Integer'Last => Occ (A, V) = 0)
      is

      begin
         Doesnt_Have_Value_To_Occ (A, Start);
         if Start < Integer'Last then
            for V in Start + 1 .. Integer'Last loop
               Doesnt_Have_Value_To_Occ (A, V);
               pragma
                 Loop_Invariant (for all P in Start .. V => Occ (A, P) = 0);
            end loop;
         end if;
      end Lemma1A;

      procedure Lemma1B (A : IArr; E : Integer)
      with
        Ghost,
        Pre  =>
          A'Last < Integer'Last
          and then A'Length < Integer'Last
          and then (for all V in Integer'First .. E => not Has_Value (A, V)),
        Post => (for all V in Integer'First .. E => Occ (A, V) = 0)
      is
      begin
         Doesnt_Have_Value_To_Occ (A, E);
         if E > Integer'First then
            for V in reverse Integer'First .. E - 1 loop
               Doesnt_Have_Value_To_Occ (A, V);
               pragma Loop_Invariant (for all P in V .. E => Occ (A, P) = 0);
            end loop;
         end if;
      end Lemma1B;

      procedure Lemma2LP (A : IArr; Biggest : Integer; C : Natural)
      with
        Ghost,
        Pre  =>
          A'Last < Integer'Last
          and then A'Length > 0
          and then A'Length < Integer'Last
          and then C in A'Range
          and then (for all V in Biggest .. Integer'Last => Occ (A, V) = 0),
        Post => A (C) < Biggest
      is
      begin
         if A (C) >= Biggest then
            pragma Assert (Occ (A, A (C)) = 0);
            Occ_To_Doesnt_Have_Value (A, A (C));
            pragma Assert (not Has_Value (A, A (C)));
            pragma Assert (Has_Value (A, A (C)));

         --  pragma Assert(False);

         end if;
      end Lemma2LP;

      procedure Lemma2L (A : IArr; Biggest : Integer)
      with
        Ghost,
        Pre  =>
          A'Last < Integer'Last
          and then A'Length > 0
          and then A'Length < Integer'Last
          and then (for all V in Biggest .. Integer'Last => Occ (A, V) = 0),
        Post => (for all P in A'Range => A (P) < Biggest)
      is
      begin
         Lemma2LP (A, Biggest, A'First);
         for P in A'First + 1 .. A'Last loop
            Lemma2LP (A, Biggest, P);
            pragma
              Loop_Invariant (for all X in A'First .. P => A (X) < Biggest);
         end loop;

      end Lemma2L;

      procedure Lemma2XL (A : IArr)
      with
        Ghost,
        Pre  =>
          A'Last < Integer'Last
          and then A'Length > 0
          and then A'Length < Integer'Last,
        Post => (for all P in A'Range => A (P) <= Integer'Last)
      is
      begin
         null;
      end Lemma2XL;

      procedure Lemma2RP (A : IArr; Smallest : Integer; C : Natural)
      with
        Ghost,
        Pre  =>
          A'Last < Integer'Last
          and then A'Length > 0
          and then A'Length < Integer'Last
          and then C in A'Range
          and then (for all V in Integer'First .. Smallest => Occ (A, V) = 0),
        Post => A (C) > Smallest
      is
      begin
         if A (C) <= Smallest then
            pragma Assert (Occ (A, A (C)) = 0);
            Occ_To_Doesnt_Have_Value (A, A (C));
            pragma Assert (not Has_Value (A, A (C)));
            pragma Assert (Has_Value (A, A (C)));
         end if;
      end Lemma2RP;

      procedure Lemma2R (A : IArr; Smallest : Integer)
      with
        Ghost,
        Pre  =>
          A'Last < Integer'Last
          and then A'Length > 0
          and then A'Length < Integer'Last
          and then (for all V in Integer'First .. Smallest => Occ (A, V) = 0),
        Post => (for all P in A'Range => Smallest < A (P))
      is
      begin
         Lemma2RP (A, Smallest, A'First);
         for P in A'First + 1 .. A'Last loop
            Lemma2RP (A, Smallest, P);
            pragma
              Loop_Invariant (for all X in A'First .. P => Smallest < A (X));
         end loop;
      end Lemma2R;

      procedure Lemma3 (A : IArr; I : Natural)
      with
        Ghost,
        Pre  =>
          A'Last < Integer'Last
          and then A'Length > 0
          and then A'Length < Integer'Last

          and then I >= A'First
          and then I <= A'Last
          and then I + 1 < Integer'Last
          and then Weak_Sorted (A (A'First .. I - 1))
          and then (if I > A'First then A (I - 1) <= A (I))
          and then (if I < A'Last then A (I) < A (I + 1))
          and then Weak_Sorted (A (I + 1 .. A'Last)),
        Post => Weak_Sorted (A)
      is
      begin
         null;
      end Lemma3;

      procedure Lemma4
      with
        Ghost,
        Pre  =>
          A'Last < Integer'Last
          and then A'Length < Integer'Last
          and then ALeft'First = A'First
          and then ALeft'Last >= A'First - 1
          and then ALeft'Last <= A'Last
          and then Multiset_Unchanged (A (ALeft'Range), AOld (ALeft'Range))
          and then ARight'First >= A'First
          and then ARight'First <= A'Last + 1
          and then ARight'Last = A'Last
          and then Multiset_Unchanged (A (ARight'Range), AOld (ARight'Range))
          and then I in A'Range
          and then ALeft'Last = I - 1
          and then ARight'First = I + 1
          and then A (I) = AOld (I),
        Post => Multiset_Unchanged (A, AOld)
      is
         LeftAndPivot    : constant IArr (A'First .. I) := A (A'First .. I);
         LeftAndPivotOld : constant IArr := AOld (LeftAndPivot'Range);
      begin
         pragma
           Assert
             (Multiset_Unchanged
                (A (A'First .. I - 1), AOld (A'First .. I - 1)));
         New_Element (LeftAndPivotOld, LeftAndPivot);
         Unchanged_Join (A, AOld, LeftAndPivot, ARight);
      end Lemma4;

      procedure Lemma5B (O, N : IArr; E : Integer)
      with
        Ghost,
        Pre  =>
          O'Length = N'Length
          and then O'First = N'First
          and then O'Last = N'Last
          and then O'Last < Integer'Last
          and then O'Length < Integer'Last
          and then Multiset_Unchanged (O, N)
          and then (for all X in Integer'First .. E => Occ (O, X) = 0),
        Post => (for all X in Integer'First .. E => Occ (N, X) = 0)
      is
      begin
         null;
      end Lemma5B;

      procedure Lemma6 (L, F : IArr)
      with
        Ghost,
        Pre  =>
          L'First = F'First
          and then L'Last <= F'Last
          and then Weak_Sorted (L (L'Range))
          and then F (L'Range) = L,
        Post => Weak_Sorted (F (L'Range))
      is
      begin
         null;
      end Lemma6;

   begin
      pragma Assert (ALeft'Last < ARight'First);
      if I > A'First then
         if A (I) < Integer'Last then
            Lemma1A (ALeft, A (I) + 1);
         end if;
         sort (ALeft);
         pragma Assert (Weak_Sorted (ALeft));
         if A (I) < Integer'Last then
            Lemma2L (ALeft, A (I) + 1);
            pragma Assert (ALeft (I - 1) <= A (I));
         elsif A (I) = Integer'Last then
            Lemma2XL (ALeft);
            pragma Assert (ALeft (I - 1) <= A (I));
         end if;

         pragma Assert (ALeft (I - 1) <= A (I));
         pragma Assert (Multiset_Unchanged (ALeft, ALeftOld));
         pragma Assert (Weak_Sorted (ALeft));
         pragma Assert (Weak_Sorted (ALeft (ALeft'Range)));

         A (ALeft'Range) := ALeft;
         pragma Assert (A (ALeft'Range) = ALeft);
         pragma Assert (Weak_Sorted (ALeft));
         Lemma6 (ALeft, A);

         pragma Assert (A (I - 1) <= A (I));
         pragma Assert (Weak_Sorted (A (ALeft'Range)));
         Equal_Implies_Multiset_Unchanged (A (ALeft'Range), ALeft);
         pragma
           Assert (Multiset_Unchanged (A (ALeft'Range), AOld (ALeft'Range)));
      else
         pragma Assert (Weak_Sorted (A (ALeft'Range)));
         pragma
           Assert (Multiset_Unchanged (A (ALeft'Range), AOld (ALeft'Range)));
      end if;
      pragma Assert (Weak_Sorted (A (ALeft'Range)));
      pragma Assert (Multiset_Unchanged (A (ALeft'Range), AOld (ALeft'Range)));
      if I < A'Last then
         Lemma1B (ARight, A (I));
         pragma Assert (Multiset_Unchanged (ARight, ARightOld));
         pragma
           Assert (for all E in Integer'First .. A (I) => Occ (ARight, E) = 0);
         sort (ARight);
         pragma Assert (Multiset_Unchanged (ARight, ARightOld));
         Lemma5B (ARightOld, ARight, A (I));
         pragma
           Assert (for all E in Integer'First .. A (I) => Occ (ARight, E) = 0);
         Lemma2R (ARight, A (I));
         pragma Assert (A (I) < ARight (I + 1));
         pragma Assert (Weak_Sorted (A (ALeft'Range)));

         pragma Assert (ARight'First > ALeft'Last);

         A (ARight'Range) := ARight;
         pragma Assert (A (ALeft'Range) = ALeft);
         pragma Assert (Weak_Sorted (ALeft));

         Lemma6 (ALeft, A);

         pragma Assert (Weak_Sorted (A (ALeft'Range)));
         pragma Assert (Multiset_Unchanged (ALeft, ALeftOld));
         Equal_Implies_Multiset_Unchanged (A (ALeft'Range), ALeft);
         pragma Assert (Weak_Sorted (A (ALeft'Range)));
         if I > A'First then
            pragma Assert (Weak_Sorted (A (ALeft'Range)));
            Unchanged_Transitivity (A (ALeft'Range), ALeft, ALeftOld);
            Unchanged_Transitivity
              (A (ALeft'Range), ALeftOld, AOld (ALeft'Range));
            pragma Assert (Weak_Sorted (A (ALeft'Range)));
            pragma
              Assert
                (Multiset_Unchanged (A (ALeft'Range), AOld (ALeft'Range)));
         end if;

         pragma Assert (A (I) < A (I + 1));
         pragma Assert (Weak_Sorted (A (ALeft'Range)));
         Equal_Implies_Multiset_Unchanged (A (ARight'Range), ARight);
         pragma
           Assert (Multiset_Unchanged (A (ARight'Range), AOld (ARight'Range)));
         pragma Assert (Weak_Sorted (A (ARight'Range)));
         pragma
           Assert (Multiset_Unchanged (A (ARight'Range), AOld (ARight'Range)));
      else
         pragma Assert (Weak_Sorted (A (ALeft'Range)));
         pragma Assert (Weak_Sorted (A (ARight'Range)));
         pragma
           Assert (Multiset_Unchanged (A (ARight'Range), AOld (ARight'Range)));
      end if;
      pragma Assert (Weak_Sorted (A (ALeft'Range)));
      pragma Assert (Weak_Sorted (A (ARight'Range)));
      --  Equal_Implies_Multiset_Unchanged(A(ALeft'Range), ALeft);
      pragma Assert (Multiset_Unchanged (A (ALeft'Range), AOld (ALeft'Range)));
      pragma
        Assert (Multiset_Unchanged (A (ARight'Range), AOld (ARight'Range)));
      Lemma3 (A, I);
      pragma Assert (Weak_Sorted (A));
      Lemma4;
      pragma Assert (Multiset_Unchanged (A, AOld));
   end Multiset_Split_Sort;

   procedure sort (A : in out IArr)
   with
     Refined_Post =>
       Weak_Sorted (A)
       and then Multiset_Unchanged (A, A'Old)
       and then (for all X in Integer'Range => (Occ (A'Old, X) = Occ (A, X)))
   is
      i          : Natural;
      j          : Natural;
      pivotvalue : constant Integer := A (A'First);
      AOld       : constant IArr (A'Range) := A
      with Ghost;
   begin
      --  Put_Line("Sorting " & Integer'Image(A'First) & " to " & Integer'Image(A'Last));
      if A'Length <= 1 then
         return;
      end if;

      i := A'First + 1;
      j := A'Last;

      while i < j loop
         pragma Loop_invariant (i > A'First);
         pragma Loop_Invariant (i < A'Last);
         pragma Loop_Invariant (j > A'First);
         pragma Loop_Invariant (j <= A'Last);
         pragma Loop_Invariant (Multiset_Unchanged (A, AOld));
         pragma Loop_Invariant (A (A'First) = AOld (A'First));
         --  pragma Loop_Variant (Decreases => (j - i));

         pragma
           Loop_Invariant
             (for all P in A'First .. i - 1 => A (P) <= pivotvalue);
         pragma
           Loop_Invariant (for all P in j + 1 .. A'Last => A (P) > pivotvalue);

         while i < j and then A (i) <= pivotvalue loop
            i := i + 1;
            pragma Loop_Invariant (i > A'First);
            pragma Loop_Invariant (i <= A'Last);
            pragma Loop_Invariant (Multiset_Unchanged (A, AOld));
            pragma
              Loop_Invariant
                (for all P in A'First .. i - 1 => A (P) <= pivotvalue);
         end loop;
         while i < j and then A (j) > pivotvalue loop
            j := j - 1;
            pragma Loop_Invariant (j > A'First);
            pragma Loop_Invariant (j <= A'Last);
            pragma Loop_Invariant (Multiset_Unchanged (A, AOld));
            pragma
              Loop_Invariant
                (for all P in j + 1 .. A'Last => A (P) > pivotvalue);
         end loop;
         if i < j then
            --  Put("swapping " & Integer'Image(i) & " and " & Integer'Image(j) & " => ");
            Swap_Array (A, i, j);
         --  for K in A'First .. A'Last loop
         --     Put(Integer'Image(A(K)) & " ");
         --  end loop;
         --  New_Line;

         end if;
      end loop;
      --  pragma Assert (i > A'First);
      --  pragma Assert (i = j);
      pragma Assert (for all P in A'First .. i - 1 => A (P) <= pivotvalue);
      pragma Assert (for all P in i + 1 .. A'Last => A (P) > pivotvalue);

      --  A(i) := pivotvalue;
      if A (i) > pivotvalue then
         i := i - 1;
      end if;

      --  pragma Assert (i >= A'First);

      pragma Assert (A (A'First) = AOld (A'First));
      Swap_Array (A, A'First, i);
      pragma Assert (A (i) = AOld (A'First));

      --  Put("Pivot " & Integer'Image(pivotvalue) & " at " & Integer'Image(i) & " => ");

      --  for K in A'First .. A'Last loop
      --     Put(Integer'Image(A(K)) & " ");
      --  end loop;
      --  New_Line;

      pragma Assert (A'Last < Integer'Last);

      Multiset_Split_Sort (A, i);
   --  pragma Assert (i <= A'Last);
   --  pragma Assert (for all P in i + 1 .. A'Last => A (P) > A (i));

   --  Put_Line("Sorted " & Integer'Image(A'First) & " to " & Integer'Image(A'Last));
   end sort;
end qsort;
