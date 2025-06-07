with Interfaces;
with Interfaces.C;

package Scheduler.IO is
   type Bytes is array (Integer range <>) of Interfaces.C.unsigned_char;
private
   procedure Wake_On_IO
     (Sched_Cx : Scheduler.Sched_Cx_Access; File : Interfaces.C.int);
end Scheduler.IO;
