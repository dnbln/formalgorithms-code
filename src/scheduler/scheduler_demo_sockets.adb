with Scheduler;
with Ada.Text_IO; use Ada.Text_IO;
with Scheduler.IO.Socket;

package body Scheduler_Demo_Sockets is
   type Demo_Root_Future_State is (Initial, Accepting, Completed);
   type Demo_Root_Future is new Scheduler.Future with record
      State : Demo_Root_Future_State;
      LS    : Scheduler.IO.Socket.Listener_Socket_Access;
   end record;

   overriding
   procedure Poll
     (F        : in out Demo_Root_Future;
      Sched_Cx : Scheduler.Sched_Cx_Access;
      Finished : out Boolean);

   type Socket_Future_State is
     (Initial, Awaiting_Read, Awaiting_Write, Completed);
   type Socket_Future is new Scheduler.Future with record
      State        : Socket_Future_State;
      Sock         : Scheduler.IO.Socket.Socket_Access;
      Buffer       : Scheduler.Bytes (1 .. 8192);
      Count        : Natural := 0;
      Write_Offset : Natural := 0;
   end record;

   overriding
   procedure Poll
     (F        : in out Socket_Future;
      Sched_Cx : Scheduler.Sched_Cx_Access;
      Finished : out Boolean);

   overriding
   procedure Poll
     (F        : in out Demo_Root_Future;
      Sched_Cx : Scheduler.Sched_Cx_Access;
      Finished : out Boolean)
   is
      Available_Data : Natural;
   begin
      case F.State is
         when Initial =>
            F.LS := Scheduler.IO.Socket.Connect_Socket ((127, 0, 0, 1), 8080);
            -- Transition to Running state
            F.State := Accepting;

            -- Here you would typically set up socket connections or similar
            -- operations. For demonstration, we will just print a message.
            Put_Line
              ("Demo Root Future initialized, transitioning to Running state.");

            Scheduler.IO.Socket.Wake_On_Connection_Requested
              (Sched_Cx => Sched_Cx, Listener => F.LS);

            Finished := False;

         when Accepting =>
            -- Simulate some work being done
            Put_Line ("Running Demo Root Future...");

            --- Gives us the number of connections in the backlog
            Available_Data :=
              Scheduler.Get_Available_Data (Sched_Cx => Sched_Cx);

            --  Put_Line
            --    ("Available connections: " & Natural'Image (Available_Data));

            for I in 1 .. Available_Data loop
               -- Accept a socket connection
               declare
                  New_Sock : Scheduler.IO.Socket.Socket_Access :=
                    Scheduler.IO.Socket.Accept_Socket (F.LS);
               begin
                  -- Create a new Socket Future for the accepted socket
                  Scheduler.Spawn
                    (Sched_Cx,
                     new Socket_Future'
                       (State        => Initial,
                        Sock         => New_Sock,
                        Buffer       => (others => <>),
                        Count        => 0,
                        Write_Offset => 1));
               end;
            end loop;
            Scheduler.IO.Socket.Wake_On_Connection_Requested
              (Sched_Cx => Sched_Cx, Listener => F.LS);
            Finished := False;

         when Completed =>
            -- Finalize the task
            Scheduler.IO.Socket.Close_Listener (F.LS);
            Put_Line ("Demo Root Future completed.");
            Finished := True;
      end case;
   end Poll;

   overriding
   procedure Poll
     (F        : in out Socket_Future;
      Sched_Cx : Scheduler.Sched_Cx_Access;
      Finished : out Boolean)
   is
      Available_Data : Natural;
      Writing_Data   : Natural;
   begin
      case F.State is
         when Initial =>
            -- Transition to Running state
            F.State := Awaiting_Read;

            -- Here you would typically set up a socket connection
            -- For demonstration, we will just print a message.
            Put_Line
              ("Socket Future initialized, transitioning to Running state.");

            Scheduler.IO.Socket.Wake_On_IO_Read
              (Sched_Cx => Sched_Cx, Socket => F.Sock);

            Finished := False;

         when Awaiting_Read =>
            -- Compute number of bytes to read
            Available_Data :=
              Scheduler.Get_Available_Data (Sched_Cx => Sched_Cx);
            if F.Buffer'Length < Available_Data then
               Available_Data := F.Buffer'Length;
            end if;

            -- read data from the socket
            Scheduler.IO.Socket.Read
              (F.Sock, F.Buffer (1 .. Available_Data), F.Count);

            if Scheduler.IO_EOF (Sched_Cx => Sched_Cx) then
               -- If no bytes were read, we assume the socket read is complete
               F.State := Completed;
               Put_Line
                 ("No data read from socket, transitioning to Completed state.");
            else
               Scheduler.IO.Socket.Wake_On_IO_Write
                 (Sched_Cx => Sched_Cx, Socket => F.Sock);

               -- Transition to Completed state
               F.State := Awaiting_Write;
            end if;

            Finished := False;

         when Awaiting_Write =>
            -- Simulate writing to the socket
            Available_Data :=
              Scheduler.Get_Available_Data (Sched_Cx => Sched_Cx);
            Writing_Data := F.Count - F.Write_Offset;

            if Writing_Data > Available_Data - 1 then
               Writing_Data := Available_Data - 1;
            end if;

            declare
               Count : Natural;
            begin
               Scheduler.IO.Socket.Write
                 (F.Sock,
                  F.Buffer (F.Write_Offset .. F.Write_Offset + Writing_Data),
                  Count);
               F.Write_Offset := F.Write_Offset + Count;
            end;

            if F.Write_Offset > F.Count then
               -- Transition to Completed state
               F.State := Awaiting_Read;
               F.Write_Offset := 1;

               Scheduler.IO.Socket.Wake_On_IO_Read
                 (Sched_Cx => Sched_Cx, Socket => F.Sock);
            else
               -- Still have data to write, continue waiting
               Scheduler.IO.Socket.Wake_On_IO_Write
                 (Sched_Cx => Sched_Cx, Socket => F.Sock);
            end if;

            Finished := False;

         when Completed =>
            -- Finalize the task
            Put_Line ("Socket Future completed.");
            Scheduler.IO.Socket.Close (F.Sock);
            Finished := True;
      end case;
   end Poll;

   procedure Run_Demo is
      Future : Scheduler.Future_Access :=
        new Demo_Root_Future'(State => Initial, LS => null);
   begin
      Scheduler.Spawn_RT (Future);
   end Run_Demo;
end Scheduler_Demo_Sockets;
