with Coroutines; use Coroutines;
pragma Elaborate_All (Coroutines);

package Test_Coroutine is
   procedure Test_Coroutine;
private
   type Delegate_A is new Delegate with null record;
   type Delegate_A_Access is access all Delegate_A;
   overriding
   procedure Run (D : in out Delegate_A);

   type Delegate_B is new Delegate with null record;
   type Delegate_B_Access is access all Delegate_B;
   overriding
   procedure Run (D : in out Delegate_B);
end Test_Coroutine;
