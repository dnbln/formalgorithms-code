with scheduler_io_h;
with unistd_h;
with sys_utypes_ussize_t_h;

package Scheduler.IO.Socket is
   type Listener_Socket is limited private;
   type Socket is limited private;

   type Listener_Socket_Access is access all Listener_Socket;
   type Socket_Access is access all Socket;

   type Address_IPv4 is array (1 .. 4) of Interfaces.C.unsigned_char;
   type Port is range 0 .. 65535;

   function Connect_Socket
     (Address : Address_IPv4; P : Port) return Listener_Socket_Access;
   function Accept_Socket (LS : Listener_Socket_Access) return Socket_Access;
   procedure Close_Listener (Socket : in out Listener_Socket_Access);
   procedure Close (Socket : in out Socket_Access);

   procedure Read
     (Socket : in out Socket_Access;
      Buffer : in out Bytes;
      Count  : out Natural)
   with Pre => Buffer'Length >= Count;
   -- Read Count bytes from Socket into Buffer.
   procedure Write
     (Socket : in out Socket_Access; Buffer : Bytes; Count : out Natural);

   procedure Wake_On_Connection_Requested
     (Sched_Cx : Scheduler.Sched_Cx_Access; Listener : Listener_Socket_Access);

   procedure Wake_On_IO_Read
     (Sched_Cx : Scheduler.Sched_Cx_Access; Socket : Socket_Access);

   procedure Wake_On_IO_Write
     (Sched_Cx : Scheduler.Sched_Cx_Access; Socket : Socket_Access);

private
   type Listener_Socket is record
      FD :
        Interfaces.C.int;  -- Socket descriptor or handle for listening socket
   end record;
   type Socket is record
      FD : Interfaces.C.int;  -- Socket descriptor or handle
   end record;
end Scheduler.IO.Socket;
