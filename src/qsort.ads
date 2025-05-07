with Lemmas.Sorted; use Lemmas.Sorted;
with Types;         use Types;

package qsort
  with SPARK_Mode
is
   procedure sort (A : in out IArr)
   with
     Pre  =>
       A'Length > 0
       and then A'First > Integer'First
       and then A'Last < Integer'Last
       and then A'Last + 1 < Integer'Last
       and then A'Length < Integer'Last
       and then A'First < Integer'Last,
     Post => Weak_Sorted (A) and then Multiset_Unchanged (A, A'Old);
end qsort;
