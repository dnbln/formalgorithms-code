package body Lemmas.Sorted is
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

   procedure New_Element (A, B : IArr) is
   begin
      null;
   end New_Element;

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

   procedure Partial_Eq (A, B : IArr; Eq : Integer; E : Integer) is
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
      if A'Length = 1 then
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
      null;
   end Unchanged_Join;

end Lemmas.Sorted;
