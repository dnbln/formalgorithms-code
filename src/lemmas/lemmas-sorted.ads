with Types; use Types;

package Lemmas.Sorted
  with Ghost, SPARK_Mode
is
   function Remove_Last (A : IArr) return IArr
   is (A (A'First .. A'Last - 1))
   with
     Pre  => A'Length > 0 and then A'Last > Integer'First,
     Post => Remove_Last'Result'Length = A'Length - 1,
     Ghost;

   function Occ_Def (A : IArr; Val : Integer) return Natural
   is (if A'Length = 0
       then 0
       elsif A (A'Last) = Val
       then Occ_Def (Remove_Last (A), Val) + 1
       else Occ_Def (Remove_Last (A), Val))
   with
     Pre                =>
       A'Last < Integer'Last and then A'Length < Integer'Last,
     Post               => Occ_Def'Result <= A'Length,
     Subprogram_Variant => (Decreases => A'Length);
   --  pragma Annotate (Gnatprove, Terminating, Occ_Def);

   function Occ (A : IArr; Val : Integer) return Natural
   is (Occ_Def (A, Val))
   with
     Pre  => A'Last < Integer'Last and then A'Length < Integer'Last,
     Post => Occ'Result <= A'Length;

   function Multiset_Retain_Rest
     (A : IArr; B : IArr; Val : Integer) return Boolean
   is (for all X in Integer => (if X /= Val then Occ (A, X) = Occ (B, X)))
   with
     Pre =>
       A'Last < Integer'Last
       and then A'Length < Integer'Last
       and then B'Last < Integer'Last
       and then B'Length < Integer'Last;

   function Multiset_Retain_Rest_Double
     (A : IArr; B : IArr; Val1 : Integer; Val2 : Integer) return Boolean
   is (for all X in Integer
       => (if X /= Val1 and then X /= Val2 then Occ (A, X) = Occ (B, X)))
   with
     Pre =>
       A'Last < Integer'Last
       and then A'Length < Integer'Last
       and then B'Last < Integer'Last
       and then B'Length < Integer'Last;

   function Multiset_Unchanged (A : IArr; B : IArr) return Boolean
   is (for all K in Integer => Occ (A, K) = Occ (B, K))
   with
     Pre =>
       A'Length = B'Length
       and then A'Last < Integer'Last
       and then A'Length < Integer'Last
       and then B'Last < Integer'Last
       and then B'Length < Integer'Last;

   function Multiset_Add (A : IArr; B : IArr; Val : Integer) return Boolean
   is (Occ (B, Val) = Occ (A, Val) + 1)
   with
     Pre =>
       A'Last < Integer'Last
       and then A'Length < Integer'Last
       and then B'Last < Integer'Last
       and then B'Length < Integer'Last;

   function Multiset_Minus (A : IArr; B : IArr; Val : Integer) return Boolean
   is (Occ (B, Val) = Occ (A, Val) - 1)
   with
     Pre =>
       A'Last < Integer'Last
       and then A'Length < Integer'Last
       and then B'Last < Integer'Last
       and then B'Length < Integer'Last;

   procedure Occ_Equal (A : IArr; B : IArr; E : Integer)
   with
     Pre  =>
       A = B and then A'Last < Integer'Last and then A'Length < Integer'Last,
     Post => Occ (A, E) = Occ (B, E);

   function Is_Set
     (A : IArr; J : Integer; V : Integer; B : IArr) return Boolean
   is (A'First = B'First
       and then A'Last = B'Last
       and then B (J) = V
       and then (for all K in A'Range => (if J /= K then B (K) = A (K))))
   with Pre => J in A'Range;

   procedure Occ_Set
     (A : IArr; B : IArr; J : Integer; V : Integer; E : Integer)
   with
     Global            => null,
     Always_Terminates => True,
     Pre               =>
       J in A'Range
       and then Is_Set (A, J, V, B)
       and then A'Last < Integer'Last
       and then A'Length < Integer'Last
       and then B'Last < Integer'Last
       and then B'Length < Integer'Last,
     Post              =>
       (if V = A (J)
        then Occ (B, E) = Occ (A, E)
        elsif V = E
        then Occ (B, E) = Occ (A, E) + 1
        elsif A (J) = E
        then Occ (B, E) = Occ (A, E) - 1
        else Occ (B, E) = Occ (A, E));

   procedure New_Element (A, B : IArr)
   with
     Global            => null,
     Always_Terminates => True,
     Pre               =>
       A'Length > 0
       and then B'Length = A'Length
       and then A'Last < Integer'Last
       and then A'Length < Integer'Last
       and then B'Last < Integer'Last
       and then B'Length < Integer'Last
       and then Multiset_Unchanged (Remove_Last (A), Remove_Last (B))
       and then A (A'Last) = B (B'Last),
     Post              => Multiset_Unchanged (A, B);

   procedure Unchanged_Join (A, T, L, R : IArr)
   with
     Global            => null,
     Always_Terminates => True,
     Pre               =>
       A'Last < Integer'Last
       and then A'Length < Integer'Last
       and then T'Last < Integer'Last
       and then L'Last < Integer'Last
       and then L'Length < Integer'Last
       and then R'Last < Integer'Last
       and then R'Length < Integer'Last
       and then T'Length < Integer'Last
       and then A'First = L'First
       and then L'Last = R'First - 1
       and then R'Last = A'Last
       and then A'First = T'First
       and then A'Last = T'Last
       and then T'First = L'First
       and then T'Last = R'Last
       and then Multiset_Unchanged (A (L'Range), T (L'Range))
       and then Multiset_Unchanged (A (R'Range), T (R'Range)),
     Post              => Multiset_Unchanged (A, T);

   procedure Unchanged_Transitivity (A, B, C : IArr)
   with
     Global            => null,
     Always_Terminates => True,

     Pre               =>
       A'Length > 0
       and then B'Length = A'Length
       and then C'Length = B'Length
       and then A'Last < Integer'Last
       and then A'Length < Integer'Last
       and then B'Last < Integer'Last
       and then B'Length < Integer'Last
       and then C'Last < Integer'Last
       and then C'Length < Integer'Last
       and then Multiset_Unchanged (A, B)
       and then (Multiset_Unchanged (B, C) or else B = C),
     Post              => Multiset_Unchanged (A, C);

   procedure Occ_To_Has_Value (A : IArr; V : Integer)
   with
     Pre  =>
       A'Length >= 1
       and then A'Last < Integer'Last
       and then A'Length < Integer'Last
       and then Occ (A, V) >= 1,
     Post => Has_Value (A, V);
   procedure Occ_To_Doesnt_Have_Value (A : IArr; V : Integer)
   with
     Global            => null,
     Always_Terminates => True,
     Pre               =>
       A'Length >= 1
       and then A'Last < Integer'Last
       and then A'Length < Integer'Last
       and then Occ (A, V) = 0,
     Post              => not Has_Value (A, V);

   procedure Has_Value_To_Occ (A : IArr; V : Integer)
   with
     Pre  => A'Length >= 1 and then Has_Value (A, V),
     Post => Occ (A, V) >= 1;

   procedure Doesnt_Have_Value_To_Occ (A : IArr; V : Integer)
   with
     Global            => null,
     Always_Terminates => True,
     Pre               => not Has_Value (A, V),
     Post              => Occ (A, V) = 0;

   procedure Partial_Eq (A, B : IArr; Eq : Integer; E : Integer)
   with
     Pre  =>
       A'Length = B'Length
       and then A'Last < Integer'Last
       and then A'Length < Integer'Last
       and then B'Last < Integer'Last
       and then B'Length < Integer'Last
       and then A'Length >= 1
       and then Eq in A'First + 1 .. A'Last
       and then (for all J in Eq .. A'Last
                 => A (J) = B (J - A'First + B'First))
       and then Occ (A, E) = Occ (B, E),
     Post =>
       Occ (A (A'First .. Eq - 1), E)
       = Occ (B (B'First .. Eq - A'First + B'First - 1), E);

   procedure Multiset_With_Eq (A, B : IArr; Eq : Integer)
   with
     Pre  =>
       A'Length = B'Length
       and then A'Last < Integer'Last
       and then A'Length < Integer'Last
       and then B'Last < Integer'Last
       and then B'Length < Integer'Last
       and then B'Last < Positive'Last
       and then A'Length >= 1
       and then Eq in A'First + 1 .. A'Last
       and then Multiset_Unchanged (A, B)
       and then (for all J in Eq .. A'Last
                 => A (J) = B (J - A'First + B'First)),
     Post =>
       Multiset_Unchanged
         (A (A'First .. Eq - 1), B (B'First .. Eq - A'First + B'First - 1));

   procedure Equal_Implies_Multiset_Unchanged (A, B : IArr)
   with
     Global            => null,
     Always_Terminates => True,
     Pre               => A = B,
     Post              => Multiset_Unchanged (A, B);

   function Has_Value (A : IArr; Val : Integer) return Boolean
   is (for some I in A'Range => A (I) = Val);

   function Weak_Sorted (A : IArr) return Boolean
   is (if A'First < Integer'Last
       then (for all I in A'First + 1 .. A'Last => A (I - 1) <= A (I))
       else True);

private

end Lemmas.Sorted;
