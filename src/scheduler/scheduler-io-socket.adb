with scheduler_io_h;
with Interfaces.C; use Interfaces.C;
with unistd_h;
with sys_utypes_ussize_t_h;

package body Scheduler.IO.Socket is
   function Connect_Socket
     (Address : Address_IPv4; P : Port) return Listener_Socket_Access
   is
      Sock : Interfaces.C.int;
   begin
      -- Implementation to connect to a socket
      Sock :=
        scheduler_io_h.listen_socket
          (ip      => Address'Address,
           port    => Interfaces.C.int (P),
           backlog => 10_000);
      if Integer (Sock) < 0 then
         raise Program_Error with "Failed to connect socket";
      end if;
      return new Listener_Socket'(FD => Sock);
   end Connect_Socket;

   function Accept_Socket (LS : Listener_Socket_Access) return Socket_Access is
      Sock : Interfaces.C.int;
      S    : Socket_Access;
   begin
      Sock := scheduler_io_h.accept_socket (LS.FD);
      if Integer (Sock) < 0 then
         raise Program_Error with "Failed to accept socket";
      end if;
      return new Socket'(FD => Sock);
   end Accept_Socket;

   procedure Close_Listener (Socket : in out Listener_Socket_Access) is
      Result : Interfaces.C.int;
   begin
      -- Implementation to close the listener socket
      if Socket /= null then
         Result := scheduler_io_h.close_listener_socket (Socket.FD);
         if Result < 0 then
            raise Program_Error with "Failed to close listener socket";
         end if;
         Socket := null;
      end if;
   end Close_Listener;

   procedure Close (Socket : in out Socket_Access) is
      Result : Interfaces.C.int;
   begin
      if Socket /= null then
         Result := scheduler_io_h.close_socket (Socket.FD);
         if Result < 0 then
            raise Program_Error with "Failed to close socket";
         end if;
         Socket := null;
      end if;
   end Close;

   procedure Read
     (Socket : in out Socket_Access;
      Buffer : in out Bytes;
      Count  : out Natural)
   is
      Fd         : constant Interfaces.C.int := Socket.FD;
      Bytes_Read : sys_utypes_ussize_t_h.ssize_t;
   begin
      Bytes_Read := unistd_h.read (Fd, Buffer'Address, Buffer'Length);
      if Bytes_Read < 0 then
         Perr ("read");
         raise Program_Error with "Failed to read from socket";
      else
         --  Ada.Text_IO.Put_Line
         --    ("Read "
         --     & sys_utypes_ussize_t_h.ssize_t'Image (Bytes_Read)
         --     & " bytes from file with FD: "
         --     & Interfaces.C.int'Image (Fd));
         Count := Natural (Bytes_Read);
      end if;
   end Read;

   procedure Write
     (Socket : in out Socket_Access; Buffer : Bytes; Count : out Natural)
   is
      Fd            : constant Interfaces.C.int := Socket.FD;
      Bytes_Written : sys_utypes_ussize_t_h.ssize_t;
   begin
      Bytes_Written := unistd_h.write (Fd, Buffer'Address, Buffer'Length);
      if Bytes_Written < 0 then
         Perr ("write");
         raise Program_Error with "Failed to write to socket";
      end if;
      Count := Natural (Bytes_Written);
   end Write;

   procedure Mark_TCP_NoDelay (Socket : Socket_Access) is
      Result : Interfaces.C.int;
   begin
      -- Implementation to set TCP_NODELAY option
      Result := scheduler_io_h.mark_tcp_nodelay (Socket.FD);
      if Result < 0 then
         raise Program_Error with "Failed to set TCP_NODELAY";
      end if;
   end Mark_TCP_NoDelay;

   procedure Wake_On_Connection_Requested
     (Sched_Cx : Scheduler.Sched_Cx_Access; Listener : Listener_Socket_Access)
   is
   begin
      Scheduler.Wake_On_IO_Read (Sched_Cx, Listener.FD);
   end Wake_On_Connection_Requested;

   procedure Wake_On_IO_Read
     (Sched_Cx : Scheduler.Sched_Cx_Access; Socket : Socket_Access) is
   begin
      Scheduler.Wake_On_IO_Read (Sched_Cx, Socket.FD);
   end Wake_On_IO_Read;

   procedure Wake_On_IO_Write
     (Sched_Cx : Scheduler.Sched_Cx_Access; Socket : Socket_Access) is
   begin
      Scheduler.Wake_On_IO_Write (Sched_Cx, Socket.FD);
   end Wake_On_IO_Write;
end Scheduler.IO.Socket;
