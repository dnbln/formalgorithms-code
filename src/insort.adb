with Lemmas.Sorted; use Lemmas.Sorted;

package body insort
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
      A_Init : constant IArr (A'Range) := A;
      Temp   : Integer := A (J);

      --  ghost variable

      A_After_First : IArr (A'Range)
      with Ghost;

      --  ghost procedure

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

   procedure more_than_sorted_after_insertion_point
     (A               : IArr;
      sorted_to       : Natural;
      value           : Integer;
      insertion_point : Integer)
   with
     Ghost,
     Pre  =>
       A'First < Integer'Last
       and then sorted_to >= 0
       and then sorted_to >= A'First
       and then sorted_to < (Integer'Last - 1)
       and then sorted_to < A'Last
       and then insertion_point >= A'First
       and then insertion_point < Integer'Last
       and then insertion_point <= sorted_to + 1
       and then A (insertion_point) > value
       and then Weak_Sorted (A (A'First .. sorted_to)),
     Post => (for all I in insertion_point .. sorted_to => A (I) > value)
   is
   begin
      --  pragma Assert (A (insertion_point) > value);
      for I in insertion_point .. sorted_to loop
         pragma
           Loop_Invariant (for all J in insertion_point .. I => A (J) > value);
      end loop;
   --  pragma Assert (for all I in insertion_point .. sorted_to => A (I) > value);
   end more_than_sorted_after_insertion_point;

   function insert_point
     (A : IArr; sorted_to : Natural; value : Integer) return Natural
   with
     Pre  =>
       A'First < Integer'Last
       and then sorted_to > 0
       and then sorted_to > A'First
       and then sorted_to < Integer'Last - 1
       and then sorted_to < A'Last
       and then sorted_to < Integer'Last
       and then A'First <= sorted_to + 1
       and then sorted_to < A'Last
       and then (for all I in A'First + 1 .. sorted_to => A (I - 1) <= A (I)),
     Post =>
       insert_point'Result >= A'First
       and then insert_point'Result <= A'Last
       and then insert_point'Result < Integer'Last
       and then insert_point'Result <= sorted_to + 1
       and then (for all I in A'First .. insert_point'Result - 1
                 => A (I) <= value)
       and then (for all I in insert_point'Result .. sorted_to
                 => A (I) > value)
   is
   begin
      if A (A'First) > value then
         more_than_sorted_after_insertion_point (A, sorted_to, value, A'First);
         --  pragma Assert (for all I in A'First ..sorted_to => A(I) > value);
         return A'First;
      end if;
      --  pragma Assert (A'First >= 0);
      for I in A'First + 1 .. sorted_to loop
         --  pragma Assert (I > 0);
         pragma
           Loop_Invariant (for all J in A'First .. I - 1 => A (J) <= value);
         if A (I) > value then
            more_than_sorted_after_insertion_point (A, sorted_to, value, I);
            --  pragma Assert (for all J in I ..sorted_to => A(J) > value);
            return I;
         end if;
      end loop;
      --  pragma Assert (for all J in A'First .. sorted_to => A(J) <= value);
      --  pragma Assert (for all J in sorted_to + 1 .. sorted_to => A (J) > value);
      return sorted_to + 1;
   end insert_point;

   procedure move_forward (A : in out IArr; from : Natural; to : Natural)
   with
     Pre  =>
       from < to
       and then A'First <= from
       and then to <= A'Last
       and then to <= Integer'Last - 1
       and then to > 0
       and then A'Last < Integer'Last
       and then A'Length < Integer'Last
       and then Weak_Sorted (A (A'First .. to - 1))
       and then (for all I in from .. to - 1 => A (to) < A (I))
       and then (for all I in A'First .. from - 1 => A (I) <= A (to)),
     Post =>
       A (from) = A'Old (to)
       and then Weak_Sorted (A (A'First .. to))
       and then Multiset_Unchanged (A, A'Old)
   is
      v    : constant Integer := A (to);
      AOld : constant IArr (A'Range) := A
      with Ghost;

      procedure Lemma_X (A, T : IArr; I, J : Natural)
      with
        Ghost,
        Pre  =>
          A'First = T'First
          and then A'Last = T'Last
          and then A'Last < Integer'Last
          and then A'Length < Integer'Last
          and then I in A'Range
          and then J in A'Range
          and then I < J
          and then A (A'First .. I - 1) = T (A'First .. I - 1)
          and then A (I) = T (J)
          and then A (I + 1 .. J) = T (I .. J - 1)
          and then A (J + 1 .. A'Last) = T (J + 1 .. T'Last),
        Post => Multiset_Unchanged (A, T)
      is
      begin
         Equal_Implies_Multiset_Unchanged
           (A (A'First .. I - 1), T (A'First .. I - 1));
         Equal_Implies_Multiset_Unchanged (A (I + 1 .. J), T (I .. J - 1));
         Equal_Implies_Multiset_Unchanged
           (A (J + 1 .. A'Last), T (J + 1 .. A'Last));
         if I = J then
            Unchanged_Join (A, T, I);
         else
            New_Element_Left_Right (A (I .. J), T (I .. J));
            pragma Assert (Multiset_Unchanged (A (I .. J), T (I .. J)));
            Unchanged_Join_3 (A, T, I, J + 1);
         end if;
      end Lemma_X;
   begin
      --  pragma Assert (for all J in A'First .. from - 1 => A (J) <= v);
      --  pragma Assert (for all J in from .. to - 1 => v < A (J));
      --  pragma Assert (if from > A'First then A (from - 1) <= v else True);
      --  pragma Assert (A (from) > v);
      pragma Assert (Multiset_Unchanged (A, AOld));

      A (to) := A (to - 1);
      Equal_Implies_Multiset_Unchanged
        (A (A'First .. from - 1), AOld (A'First .. from - 1));
      Equal_Implies_Multiset_Unchanged
        (A (to + 1 .. A'Last), AOld (to + 1 .. A'Last));
      for I in reverse from .. to - 1 loop
         pragma
           Loop_Invariant (for all J in A'First .. from - 1 => A (J) <= v);
         pragma Loop_Invariant (for all J in from .. to - 1 => A (J) > v);
         pragma Loop_Invariant (Weak_Sorted (A (A'First .. to)));
         pragma
           Loop_Invariant
             (A (A'First .. from - 1) = AOld (A'First .. from - 1));
         pragma
           Loop_Invariant (A (to + 1 .. A'Last) = AOld (to + 1 .. A'Last));
         pragma
           Loop_Invariant
             (Multiset_Unchanged
                (A (A'First .. from - 1), AOld (A'First .. from - 1)));
         pragma
           Loop_Invariant
             (Multiset_Unchanged
                (A (to + 1 .. A'Last), AOld (to + 1 .. A'Last)));
         pragma Loop_Invariant (A (from .. I) = AOld (from .. I));
         pragma Loop_Invariant (A (I + 2 .. to) = AOld (I + 1 .. to - 1));
         A (I + 1) := A (I);

         Equal_Implies_Multiset_Unchanged
           (A (A'First .. from - 1), AOld (A'First .. from - 1));
         Equal_Implies_Multiset_Unchanged
           (A (to + 1 .. A'Last), AOld (to + 1 .. A'Last));
      end loop;
      pragma Assert (A (from + 1 .. to) = AOld (from .. to - 1));
      --  pragma Assert (for all J in A'First + 1 .. to => A (J - 1) <= A(J));
      pragma Assert (if to >= from + 1 then v < A (from + 1));
      pragma Assert (if from > A'First then A (from - 1) <= v);
      A (from) := v;
      pragma Assert (A (from + 1 .. to) = AOld (from .. to - 1));
      Lemma_X (A, AOld, from, to);
   --  pragma Assert (for all J in A'First + 1 .. from - 1 => A (J - 1) <= A(J));
   --  pragma Assert (for all J in from + 2 .. to => A (J - 1) <= A(J));
   --  pragma Assert (if from > A'First then A (from - 1) <= A(from) else True);
   end move_forward;

   procedure sort (A : in out IArr)
   with Refined_Post => Weak_Sorted (A) and then Multiset_Unchanged (A, A'Old)
   is
      ipt  : Natural;
      AOld : constant IArr (A'Range) := A
      with Ghost;
   begin
      if A'Length < 2 then
         return;
      end if;
      if A (A'First) > A (A'First + 1) then
         --  pragma Assert (A'First /= A'First + 1);
         Swap_Array (A, (A'First), (A'First + 1));
      --  pragma Assert (A (A'First) < A(A'First + 1));

      end if;
      --  pragma Assert (A (A'First) <= A(A'First + 1));

      for I in A'First + 1 .. A'Last - 1 loop
         pragma Loop_Invariant (Weak_Sorted (A (A'First .. I)));
         pragma Loop_Invariant (Multiset_Unchanged (A, AOld));
         --  pragma Assert (I > 0);

         --  pragma Assert (I < Integer'Last);
         ipt := insert_point (A, I, A (I + 1));
         --  pragma Assert (for all J in A'First .. ipt - 1 => A (J) <= A(I+1));
         --  pragma Assert (for all J in ipt .. I => A (J) > A(I + 1));
         if ipt < I + 1 then
            move_forward (A, ipt, I + 1);
         --  pragma Assert (for all J in A'First + 1 .. I + 1 => A (J - 1) <= A(J));

         else
            --  pragma Assert (ipt = I + 1);
            null;
         end if;

         --  pragma Assert (for all J in A'First + 1 .. I + 1 => A (J - 1) <= A(J));

      end loop;
   end sort;

end insort;
