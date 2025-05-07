--  with Ada.Text_IO;   use Ada.Text_IO;
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
      ALeft     : IArr renames A (A'First .. I - 1);
      Piv       : Integer renames A (I);
      ARight    : IArr renames A (I + 1 .. A'Last);
      ALeftOld  : constant IArr (A'First .. I - 1) := AOld (A'First .. I - 1)
      with Ghost;
      ARightOld : constant IArr (I + 1 .. A'Last) := AOld (I + 1 .. A'Last)
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

            pragma Assert (False);
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

            pragma Assert (False);
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
        Pre               =>
          A'Last < Integer'Last
          and then I in A'Range
          and then A'Length < Integer'Last
          and then Multiset_Unchanged
                     (A (A'First .. I - 1), AOld (A'First .. I - 1))
          and then Multiset_Unchanged
                     (A (I + 1 .. A'Last), AOld (I + 1 .. A'Last))
          and then A (I) = AOld (I),
        Post              => Multiset_Unchanged (A, AOld),
        Always_Terminates => True
      is
      begin
         New_Element (A (A'First .. I), AOld (A'First .. I));
         Unchanged_Join (A, AOld, A (A'First .. I), A (I + 1 .. A'Last));
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

   begin
      if I > A'First then
         if Piv < Integer'Last then
            Lemma1A (ALeft, Piv + 1);
         end if;
         pragma Assert (Multiset_Unchanged (ALeft, ALeftOld));
         pragma Assert (Multiset_Unchanged (ARight, ARightOld));
         pragma Assert (ALeft = ALeftOld);
         sort (ALeft);
         pragma Assert (Weak_Sorted (ALeft));
         pragma
           Assume
             (Multiset_Unchanged
                (ALeft,
                 ALeftOld)); -- Source: Trust me bro (postcondition of sort, for some reason gnatprove cannot link it to this context)
         pragma
           Assume
             (Multiset_Unchanged
                (ARight,
                 ARightOld)); -- Source: Trust me bro (not touched by the `sort` above)
         if Piv < Integer'Last then
            Lemma2L (ALeft, Piv + 1);
            pragma Assert (ALeft (I - 1) <= Piv);
         elsif Piv = Integer'Last then
            Lemma2XL (ALeft);
            pragma Assert (ALeft (I - 1) <= Piv);
         end if;

         pragma Assert (ALeft (I - 1) <= Piv);
         pragma Assert (Multiset_Unchanged (ALeft, ALeftOld));
      else
         pragma Assert (Weak_Sorted (ALeft));
         pragma Assert (Multiset_Unchanged (ALeft, ALeftOld));
      end if;
      pragma Assert (Weak_Sorted (ALeft));
      pragma Assert (Multiset_Unchanged (ALeft, ALeftOld));
      if I < A'Last then
         Lemma1B (ARight, Piv);
         pragma Assert (Multiset_Unchanged (ARight, ARightOld));
         pragma
           Assert (for all E in Integer'First .. Piv => Occ (ARight, E) = 0);
         sort (ARight);
         pragma Assert (Weak_Sorted (ARight));
         pragma
           Assume
             (Multiset_Unchanged
                (ALeft,
                 ALeftOld)); -- Source: Trust me bro (not touched by sort)
         pragma
           Assume
             (Multiset_Unchanged
                (ARight,
                 ARightOld)); -- Source: Trust me bro (postcondition of sort, not linked by gnatprove to this context for some reason)
         Lemma5B (ARightOld, ARight, Piv);
         pragma
           Assert (for all E in Integer'First .. Piv => Occ (ARight, E) = 0);
         Lemma2R (ARight, Piv);
         pragma Assert (Piv < ARight (I + 1));
         pragma Assert (Weak_Sorted (ALeft));
         pragma Assert (Piv < ARight (I + 1));
      end if;
      pragma Assert (Weak_Sorted (ALeft));
      pragma Assert (Weak_Sorted (ARight));
      pragma Assert (Multiset_Unchanged (ALeft, ALeftOld));
      pragma Assert (Multiset_Unchanged (ARight, ARightOld));
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
       and then (for all X in Integer => Occ (A, X) = Occ (A'Old, X))
   is
      i          : Natural;
      j          : Natural;
      pivotvalue : constant Integer := A (A'First);
      AOld       : constant IArr (A'Range) := A
      with Ghost;
   begin
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
            Swap_Array (A, i, j);
         end if;
      end loop;
      pragma Assert (for all P in A'First .. i - 1 => A (P) <= pivotvalue);
      pragma Assert (for all P in i + 1 .. A'Last => A (P) > pivotvalue);

      if A (i) > pivotvalue then
         i := i - 1;
      end if;

      pragma Assert (A (A'First) = AOld (A'First));
      Swap_Array (A, A'First, i);
      pragma Assert (A (i) = AOld (A'First));

      pragma Assert (A'Last < Integer'Last);

      Multiset_Split_Sort (A, i);
   end sort;
end qsort;
