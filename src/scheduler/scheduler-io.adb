package body Scheduler.IO is

   procedure Wake_On_IO
     (Sched_Cx : Scheduler.Sched_Cx_Access; File : Interfaces.C.int) is
   begin
      Sched_Cx.Sched_IO := new Interfaces.C.int' (File);
   end Wake_On_IO;

end Scheduler.IO;
