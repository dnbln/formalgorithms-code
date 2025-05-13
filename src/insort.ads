with Types;         use Types;
with Lemmas.Sorted; use Lemmas.Sorted;

package insort
  with SPARK_Mode => On
is
   procedure sort (A : in out IArr)
   with
     Pre  =>
       A'Last > 0
       and then A'First < Integer'Last
       and then A'Last < Integer'Last
       and then A'Length < Integer'Last,
     Post => Weak_Sorted (A) and then Multiset_Unchanged (A, A'Old);

end insort;
