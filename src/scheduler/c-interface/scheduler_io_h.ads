pragma Ada_2012;

pragma Style_Checks (Off);
pragma Warnings (Off, "-gnatwu");

with Interfaces.C; use Interfaces.C;
with Interfaces.C.Strings;
with System;
limited with sys_event_h;

package scheduler_io_h is

   function create_kqueue return int  -- ./scheduler_io.h:6
   with Import => True, Convention => C, External_Name => "create_kqueue";

   function register_event
     (kq : int; fd : int; filter : short; udata : System.Address)
      return int  -- ./scheduler_io.h:8
   with Import => True, Convention => C, External_Name => "register_event";

   function unregister_event
     (kq : int; fd : int; filter : short) return int  -- ./scheduler_io.h:9
   with Import => True, Convention => C, External_Name => "unregister_event";

   function poll_events
     (kq : int; events : System.Address; max_events : int)
      return int  -- ./scheduler_io.h:11
   with Import => True, Convention => C, External_Name => "poll_events";

   procedure advise_sequencial (fd : int)  -- ./scheduler_io.h:13
   with Import => True, Convention => C, External_Name => "advise_sequencial";

   function listen_socket
     (ip : System.Address; port : int; backlog : int)
      return int  -- ./scheduler_io.h:15
   with Import => True, Convention => C, External_Name => "listen_socket";

   function accept_socket (lfd : int) return int  -- ./scheduler_io.h:16
   with Import => True, Convention => C, External_Name => "accept_socket";

   function close_listener_socket
     (lfd : int) return int  -- ./scheduler_io.h:17
   with
     Import        => True,
     Convention    => C,
     External_Name => "close_listener_socket";

   function close_socket (sfd : int) return int  -- ./scheduler_io.h:18
   with Import => True, Convention => C, External_Name => "close_socket";

   procedure call_perror
     (msg : Interfaces.C.Strings.chars_ptr) -- ./scheduler_io.h:20
   with Import => True, Convention => C, External_Name => "call_perror";

end scheduler_io_h;

pragma Style_Checks (On);
pragma Warnings (On, "-gnatwu");
