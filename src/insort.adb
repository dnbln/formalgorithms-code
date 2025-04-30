package body insort with SPARK_Mode => On is
   procedure more_than_sorted_after_insertion_point (A : Arr; sorted_to: Natural; value: Integer; insertion_point: Integer)
     with Ghost,
     Pre => (
            (A'First < Integer'Last and then
                 sorted_to >= 0 and then sorted_to >= A'First and then sorted_to < (Integer'Last - 1) and then sorted_to < A'Last)
     and then
       (insertion_point >= A'First and then insertion_point < Integer'Last and then insertion_point <= sorted_to + 1)
       and then
         (A (insertion_point) > value and (for all I in A'First + 1 .. sorted_to => A (I - 1) <= A(I)))
     ),
     Post => (
                (for all I in insertion_point .. sorted_to => A (I) > value)
             )

   is
   begin
      pragma Assert (A (insertion_point) > value);
      for I in insertion_point .. sorted_to loop
         pragma Loop_Invariant (for all J in insertion_point .. I => A (J) > value);
      end loop;
      pragma Assert (for all I in insertion_point .. sorted_to => A (I) > value);
   end more_than_sorted_after_insertion_point;

   function insert_point (A : Arr; sorted_to: Natural; value: Integer) return Natural
     with
       Pre => (
               (A'First < Integer'Last and then
                 sorted_to > 0 and then sorted_to > A'First and then sorted_to < (Integer'Last - 1) and then sorted_to < A'Last) and then
                 (
                  (sorted_to < Integer'Last) and then
                    (A'First <= sorted_to + 1) and then
                      (sorted_to < A'Last) and then
                      (for all I in A'First + 1 .. sorted_to => A (I - 1) <= A(I))
                 )
              ),
       Post => (
                  insert_point'Result >= A'First and then
                  insert_point'Result <= A'Last and then
                  insert_point'Result < Integer'Last and then
                  insert_point'Result <= sorted_to + 1 and then
                    (for all I in A'First .. insert_point'Result - 1 => A (I) <= value) and then
                  (for all I in insert_point'Result .. sorted_to => A (I) > value)
               )
   is
   begin
      if A (A'First) > value then
         more_than_sorted_after_insertion_point (A, sorted_to, value, A'First);
         pragma Assert (for all I in A'First ..sorted_to => A(I) > value);
         return A'First;
      end if;
      pragma Assert (A'First >= 0);
      for I in A'First + 1 .. sorted_to loop
         pragma Assert (I > 0);
         pragma Loop_Invariant (for all J in A'First .. I - 1 => A(J) <= value);
         if A (I) > value then
            more_than_sorted_after_insertion_point (A, sorted_to, value, I);
            pragma Assert (for all J in I ..sorted_to => A(J) > value);
            return I;
         end if;
      end loop;
      pragma Assert (for all J in A'First .. sorted_to => A(J) <= value);
      pragma Assert (for all J in sorted_to + 1 .. sorted_to => A (J) > value);
      return sorted_to + 1;
   end insert_point;

   procedure move_forward (A : in out Arr; from: Natural; to: Natural)
     with
       Pre => (
                 ((from < to) and then
                   (A'First <= from) and then
                   (to <= A'Last) and then to <= Integer'Last - 1 and then to > 0)
               and then
                 ((for all I in A'First + 1 .. to - 1 => A (I - 1) <= A (I))
                  and then
                    (for all I in from .. to - 1 => A (to) < A (I))
                     and then
                    (for all I in A'First .. from - 1 => A(I) <= A(to))
                 )
              ),
       Post => (
                  A (from) = A'Old (to) and then
                    (for all I in A'First + 1 .. to => A (I - 1) <= A(I))
               )
   is
      v : constant Integer := A (to);
   begin
      pragma Assert (for all J in A'First .. from - 1 => A (J) <= v);
      pragma Assert (for all J in from .. to - 1 => v < A (J));
      pragma Assert (if from > A'First then A (from - 1) <= v else True);
      pragma Assert (A (from) > v);
      A(to) := A(to-1);
      for I in reverse from..to-1 loop
         pragma Loop_Invariant ((for all J in A'First .. from - 1 => A (J) <= v) and then
                                  (for all J in from .. to - 1 => A (J) > v) and then
                                (for all J in A'First + 1 .. to => A(J - 1) <= A(J))
                               );
         A (I + 1) := A (I);
      end loop;
      pragma Assert (for all J in A'First + 1 .. to => A (J - 1) <= A(J));
      pragma Assert (if to >= from + 1 then v < A (from + 1) else True);

      pragma Assert (if from > A'First then A (from - 1) <= v else True);
      A (from) := v;
      pragma Assert (for all J in A'First + 1 .. from - 1 => A (J - 1) <= A(J));
      pragma Assert (for all J in from + 2 .. to => A (J - 1) <= A(J));
      pragma Assert (if from > A'First then A (from - 1) <= A(from) else True);
   end move_forward;

   procedure swp (A : in out Arr; I, J: Natural)
     with
       Pre => A'First <= I and then I < J and then J <= A'Last,
       Post => ((A (I) = A'Old (J)) and then (A(J) = A'Old(I)))
   is
      tmp : constant Integer := A (I);
   begin
      A (I) := A (J);
      A (J) := tmp;
   end swp;

   procedure sort (A : in out Arr)
     with
       Refined_Post => (for all I in A'First + 1 .. A'Last => A (I - 1) <= A (I))
   is
      ipt : Natural;
   begin
      if A'Length < 2 then
         return;
      end if;
      if A (A'First) > A (A'First + 1) then
         pragma Assert (A'First /= A'First + 1);
         swp (A, (A'First), (A'First + 1));
         pragma Assert (A (A'First) < A(A'First + 1));
      end if;
      pragma Assert (A (A'First) <= A(A'First + 1));

      for I in A'First + 1 .. A'Last - 1 loop
         pragma Loop_Invariant (for all J in A'First + 1 ..I => A(J-1) <= A(J));
         pragma Assert (I > 0);

         pragma Assert (I < Integer'Last);
         ipt := insert_point (A, I, A (I + 1));
         pragma Assert (for all J in A'First .. ipt - 1 => A (J) <= A(I+1));
         pragma Assert (for all J in ipt .. I => A (J) > A(I + 1));
         if ipt < I + 1 then
            move_forward (A, ipt, I + 1);
            pragma Assert (for all J in A'First + 1 .. I + 1 => A (J - 1) <= A(J));
         else
            pragma Assert (ipt = I + 1);
         end if;

         pragma Assert (for all J in A'First + 1 .. I + 1 => A (J - 1) <= A(J));

      end loop;
   end sort;

end insort;
