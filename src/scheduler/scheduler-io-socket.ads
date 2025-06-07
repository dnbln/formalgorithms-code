package Scheduler.IO.Socket is
   type Socket is private;

   function Connect_Socket (Address : String; Port : Integer) return Socket;
   function Accept_Socket (Socket : Socket) return Socket;
   procedure Close (Socket : in out Socket);

   procedure Read
     (Socket : in out Socket; Buffer : in out Bytes; Count : out Positive)
   with Pre => Buffer'Length >= Count;
   -- Read Count bytes from Socket into Buffer.
   procedure Write (Socket : in out Socket; Buffer : Bytes);

   procedure Wake_On_IO
     (Sched_Cx : Scheduler.Sched_Cx_Access; Socket : Socket);

private
   type Socket is record
      FD : Integer;  -- Socket descriptor or handle
   end record;
end Scheduler.IO.Socket;
