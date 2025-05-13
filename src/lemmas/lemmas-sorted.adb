package body Lemmas.Sorted
  with SPARK_Mode
is
   procedure Occ_Equal (A : IArr; B : IArr; E : Integer) is
   begin
      if A'Length = 0 then
         return;
      end if;

      if A (A'Last) = E then
         pragma Assert (B (B'Last) = E);
      else
         pragma Assert (B (B'Last) /= E);
      end if;

      Occ_Equal (Remove_Last (A), Remove_Last (B), E);
   end Occ_Equal;

   procedure Occ_Set
     (A : IArr; B : IArr; J : Integer; V : Integer; E : Integer)
   is
      Tmp : IArr := Remove_Last (A);
   begin
      if A'Length = 0 then
         return;
      end if;

      if J = A'Last then
         Occ_Equal (Tmp, Remove_Last (B), E);
      else
         Tmp (J) := V;
         Occ_Equal (Remove_Last (B), Tmp, E);
         Occ_Set (Remove_Last (A), Tmp, J, V, E);
      end if;
   end Occ_Set;

   procedure Lemma_Occ_Left_And_Right_Eq (A : IArr; Val : Integer) is
   begin
      if A'Length <= 1 then
         return;
      end if;
      Lemma_Occ_Left_And_Right_Eq (Remove_First (A), Val);
      Lemma_Occ_Left_And_Right_Eq (Remove_Last (A), Val);
      Lemma_Occ_Left_And_Right_Eq (Remove_First (Remove_Last (A)), Val);
   end Lemma_Occ_Left_And_Right_Eq;

   procedure New_Element (A, B : IArr) is
   begin
      null;
   end New_Element;

   procedure New_Element_Left_Right (A, B : IArr) is
   begin
      pragma
        Assert
          (Occ_Def_Left (Remove_First (A), A (A'First)) + 1
             = Occ_Def_Left (A, A (A'First)));
      pragma Assert (Multiset_Add (Remove_Last (B), B, B (B'Last)));
      if not Multiset_Unchanged (A, B) then
         Lemma_Occ_Left_And_Right_Eq (A, Integer'First);
         Lemma_Occ_Left_And_Right_Eq (Remove_First (A), Integer'First);
         for I in Integer'First + 1 .. Integer'Last loop
            pragma
              Loop_Invariant
                (for all J in Integer'First .. I - 1
                 => (Occ_Def (A, J) = Occ_Def_Left (A, J)));
            pragma
              Loop_Invariant
                (for all J in Integer'First .. I - 1
                 => (Occ_Def (Remove_First (A), J)
                     = Occ_Def_Left (Remove_First (A), J)));
            Lemma_Occ_Left_And_Right_Eq (A, I);
            Lemma_Occ_Left_And_Right_Eq (Remove_First (A), I);
         end loop;
         pragma
           Assert
             (for all X in Integer => Occ_Def (A, X) = Occ_Def_Left (A, X));
         pragma
           Assert
             (for all X in Integer
              => Occ_Def (Remove_First (A), X)
                 = Occ_Def_Left (Remove_First (A), X));
         pragma
           Assert
             (for all X in Integer
              => Occ (Remove_First (A), X) = Occ (Remove_Last (B), X));
         pragma
           Assert
             (for all X in Integer
              => Occ_Def_Left (A, X)
                 = Occ_Def_Left (Remove_First (A), X)
                   + (if A (A'First) = X then 1 else 0));
         pragma
           Assert (for all X in Integer => Occ (A, X) = Occ_Def_Left (A, X));
         pragma
           Assert
             (for all X in Integer
              => Occ (B, X)
                 = Occ (Remove_Last (B), X)
                   + (if B (B'Last) = X then 1 else 0));
         pragma
           Assert
             (for all X in Integer
              => Occ (Remove_Last (B), X) = Occ (Remove_First (A), X));
         pragma Assert (for some X in Integer => Occ (A, X) /= Occ (B, X));
         pragma
           Assert
             (for some X in Integer
              => Occ_Def_Left (Remove_First (A), X)
                 + (if A (A'First) = X then 1 else 0)
                 /= Occ (Remove_Last (B), X)
                    + (if B (B'Last) = X then 1 else 0));
         pragma
           Assert
             (for some X in Integer
              => Occ_Def_Left (Remove_First (A), X)
                 /= Occ (Remove_Last (B), X));
         pragma Assert (False);
      end if;
   end New_Element_Left_Right;

   procedure Unchanged_Transitivity (A, B, C : IArr) is
   begin
      if B = C then
         Equal_Implies_Multiset_Unchanged (B, C);
      end if;
   end Unchanged_Transitivity;

   procedure Occ_To_Has_Value (A : IArr; V : Integer) is
   begin
      if A'Length = 1 then
         return;
      end if;
      if A (A'Last) = V then
         return;
      else
         Occ_To_Has_Value (Remove_Last (A), V);
      end if;

   end Occ_To_Has_Value;

   procedure Has_Value_To_Occ (A : IArr; V : Integer) is
   begin
      if A'Length = 1 then
         pragma Assert (A (A'First) = V);
         return;
      end if;

      if A (A'Last) = V then
         pragma Assert (Occ (Remove_Last (A), V) >= 0);
         pragma Assert (Occ (A, V) >= 1);
         return;
      else
         Has_Value_To_Occ (Remove_Last (A), V);
      end if;
   end Has_Value_To_Occ;

   procedure Partial_Eq (A, B : IArr; Eq : Integer; E : Integer)
   with
     Refined_Post =>
       Occ (A (A'First .. Eq - 1), E)
       = Occ (B (B'First .. Eq - A'First + B'First - 1), E)
   is
   begin
      if A'Last = Eq then
         return;
      end if;

      if A (A'Last) = E then
         pragma Assert (B (B'Last) = E);
      else
         pragma Assert (B (B'Last) /= E);
      end if;

      Partial_Eq (Remove_Last (A), Remove_Last (B), Eq, E);
   end Partial_Eq;

   procedure Multiset_With_Eq (A, B : IArr; Eq : Integer) is
      Eq_B : constant Natural := Eq - A'First + B'First;
   begin
      for E in Integer loop
         Partial_Eq (A, B, Eq, E);
         pragma
           Loop_Invariant
             (for all F in Integer'First .. E
              => Occ (A (A'First .. Eq - 1), F)
                 = Occ (B (B'First .. Eq_B - 1), F));
      end loop;

   end Multiset_With_Eq;

   procedure Equal_Implies_Multiset_Unchanged (A, B : IArr) is
   begin
      for V in Integer loop
         Occ_Equal (A, B, V);
         pragma
           Loop_Invariant
             (for all E in Integer'First .. V => Occ (A, E) = Occ (B, E));
      end loop;
   end Equal_Implies_Multiset_Unchanged;

   procedure Occ_To_Doesnt_Have_Value (A : IArr; V : Integer) is
   begin
      if A'Length = 1 then
         pragma Assert (not Has_Value (A, V));
         return;
      end if;

      if A (A'Last) = V then
         pragma Assert (Occ (Remove_Last (A), V) = 0);
         pragma Assert (not Has_Value (A, V));
         return;
      else
         Occ_To_Doesnt_Have_Value (Remove_Last (A), V);
      end if;
   end Occ_To_Doesnt_Have_Value;

   procedure Doesnt_Have_Value_To_Occ (A : IArr; V : Integer) is
   begin
      if A'Length <= 1 then
         pragma Assert (not Has_Value (A, V));
         return;
      end if;

      if A (A'Last) = V then
         pragma Assert (Occ (Remove_Last (A), V) = 0);
         pragma Assert (not Has_Value (A, V));
         return;
      else
         Doesnt_Have_Value_To_Occ (Remove_Last (A), V);
      end if;
   end Doesnt_Have_Value_To_Occ;

   procedure Unchanged_Join (A, T, L, R : IArr)
   with Refined_Post => Multiset_Unchanged (A, T)
   is
   begin
      if not Multiset_Unchanged (A, T) then
         pragma Assert (for some X in Integer => Occ (A, X) /= Occ (T, X));

         --  pragma Assert (for all X in Integer => Occ(A(L'Range), X) = Occ(T(L'Range), X));
         --  pragma Assert (for all X in Integer => Occ(A(R'Range), X) = Occ(T(R'Range), X));

         Occ_Join_Lemma (A, L'Last, Integer'First);
         for X in Integer'First + 1 .. Integer'Last loop
            pragma
              Loop_Invariant
                (for all V in Integer'First .. X - 1
                 => Occ (A, V) = Occ (A (L'Range), V) + Occ (A (R'Range), V));
            Occ_Join_Lemma (A, L'Last, X);
         end loop;
         --  pragma Assert (for all X in Integer => Occ(A, X) = Occ(A(L'Range), X) + Occ(A(R'Range), X));

         Occ_Join_Lemma (T, L'Last, Integer'First);
         for X in Integer'First + 1 .. Integer'Last loop
            pragma
              Loop_Invariant
                (for all V in Integer'First .. X - 1
                 => Occ (T, V) = Occ (T (L'Range), V) + Occ (T (R'Range), V));
            Occ_Join_Lemma (T, L'Last, X);
         end loop;
         --  pragma Assert (for all X in Integer => Occ(T, X) = Occ(T(L'Range), X) + Occ(T(R'Range), X));

         pragma Assert (for all X in Integer => Occ (A, X) = Occ (T, X));
         pragma Assert (False);
      end if;
   end Unchanged_Join;

   procedure Unchanged_Join_3 (A, T, L, M, R : IArr)
   with Refined_Post => Multiset_Unchanged (A, T)
   is
   begin
      Unchanged_Join (A (L'First .. M'Last), T (L'First .. M'Last), L, M);
      Unchanged_Join (A, T, A (L'First .. M'Last), R);
   end Unchanged_Join_3;

   procedure Weak_Sorted_To_Def (A : IArr)
   with
     Refined_Post => (for all I in A'First + 1 .. A'Last => A (I - 1) <= A (I))
   is
   begin
      null;
   end Weak_Sorted_To_Def;

   procedure Weak_Sorted_Subrange (A, S : IArr)
   with Refined_Post => Weak_Sorted (A (S'Range))
   is
   begin
      null;
   end Weak_Sorted_Subrange;

   procedure Occ_Join_Lemma (A : IArr; P : Natural; X : Integer)
   with
     Refined_Post =>
       (Occ_Def (A, X)
        = Occ_Def (A (A'First .. P), X) + Occ_Def (A (P + 1 .. A'Last), X))
   is
   begin
      if P = A'Last then
         --  if A(P) = X then
         --  pragma Assert(Occ_Def(A(P..P), X) = 1);
         --  pragma Assert(Occ_Def(A(P..A'Last), X) = Occ_Def(A(P..P), X));
         --  pragma Assert(Occ_Def(A, X) = Occ_Def(A(A'First..P-1), X) + Occ_Def(A(P..A'Last), X));
         --  else
         --  pragma Assert(Occ_Def(A(P..P), X) = 0);
         --  pragma Assert(Occ_Def(A(P..A'Last), X) = Occ_Def(A(P..P), X));
         --  pragma Assert(Occ_Def(A, X) = Occ_Def(A(A'First..P-1), X) + Occ_Def(A(P..A'Last), X));
         --  end if;
         return;
      end if;

      Occ_Join_Lemma (A, P + 1, X);
      --  pragma Assert(Occ_Def(A, X) = Occ_Def(A(A'First..P+1), X) + Occ_Def(A(P+2..A'Last), X));
      --  pragma Assert(Occ_Def(A(A'First..P+1), X) = Occ_Def(A(A'First..P), X) + Occ_Def(A(P+1..P+1), X));
      Occ_Join_Lemma (A (P + 1 .. A'Last), P + 1, X);
   --  pragma Assert(Occ_Def(A(P+1..A'Last), X) = Occ_Def(A(P+1..P+1), X) + Occ_Def(A(P + 2..A'Last), X));
   end Occ_Join_Lemma;

end Lemmas.Sorted;
