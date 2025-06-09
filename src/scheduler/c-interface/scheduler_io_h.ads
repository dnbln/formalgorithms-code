pragma Ada_2012;

pragma Style_Checks (Off);
pragma Warnings (Off, "-gnatwu");

with Interfaces.C; use Interfaces.C;
with System;
limited with sys_event_h;

package scheduler_io_h is

   function create_kqueue return int  -- ./scheduler_io.h:4
   with Import => True, 
        Convention => C, 
        External_Name => "create_kqueue";

   function register_event
     (kq : int;
      fd : int;
      filter : short;
      udata : System.Address) return int  -- ./scheduler_io.h:6
   with Import => True, 
        Convention => C, 
        External_Name => "register_event";

   function unregister_event
     (kq : int;
      fd : int;
      filter : short) return int  -- ./scheduler_io.h:7
   with Import => True, 
        Convention => C, 
        External_Name => "unregister_event";

   function poll_events
     (kq : int;
      events : System.Address;
      max_events : int) return int  -- ./scheduler_io.h:8
   with Import => True, 
        Convention => C, 
        External_Name => "poll_events";

end scheduler_io_h;

pragma Style_Checks (On);
pragma Warnings (On, "-gnatwu");
