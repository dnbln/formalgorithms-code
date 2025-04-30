package insort with SPARK_Mode => On is
   type Arr is array (Natural range <>) of Integer;

   procedure sort (A: in out Arr)
     with
       Pre => A'Last > 0 and then A'First < Integer'Last and then A'Last < Integer'Last,
     Post  => (for all I in A'First + 1 .. A'Last => A (I - 1) <= A(I))
         and then (for all I in A'Range => (for some X in A'Range => A'Old (I) = A(X)));

end insort;
