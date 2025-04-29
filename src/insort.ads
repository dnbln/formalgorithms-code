package insort with SPARK_Mode => On is
   type Arr is array(Natural range <>) of Integer;

   procedure sort(A: in out Arr)
     with
       Pre => A'Last > 0 and A'First < Integer'Last and A'Last < Integer'Last,
     Post  => (for all I in A'First + 1 .. A'Last => A(I - 1) <= A(I));


end insort;
