with Ada.Text_IO;
with Interfaces.C; use Interfaces.C;
with Interfaces.C.Strings;
with sys_fcntl_h;
with unistd_h;
with sys_utypes_ussize_t_h;

package body Scheduler.IO.File is
   type Mod_Int is mod 2**32;

   function Open_Read (Path : String) return File_Access is
      P       : Interfaces.C.Strings.chars_ptr :=
        Interfaces.C.Strings.New_String (Path);
      Fd      : Interfaces.C.int;
      FAccess : File_Access;
   begin
      Ada.Text_IO.Put_Line ("Opening file for reading: " & Path);
      Fd := sys_fcntl_h.open (P, Interfaces.C.int (sys_fcntl_h.O_RDONLY));
      Interfaces.C.Strings.Free (P);
      if Integer (Fd) < 0 then
         raise Program_Error with "Failed to open file for reading";
      end if;
      FAccess := new File'(FD => Fd);
      return FAccess;
   end Open_Read;

   function Open_Write (Path : String) return File_Access is
      P       : Interfaces.C.Strings.chars_ptr :=
        Interfaces.C.Strings.New_String (Path);
      Fd      : Interfaces.C.int;
      FAccess : File_Access;
   begin
      Fd :=
        sys_fcntl_h.open
          (P,
           Interfaces.C.int
             (Mod_Int (sys_fcntl_h.O_WRONLY)
              or Mod_Int (sys_fcntl_h.O_CREAT)
              or Mod_Int (sys_fcntl_h.O_TRUNC)));
      Interfaces.C.Strings.Free (P);
      if Integer (Fd) < 0 then
         raise Program_Error with "Failed to open file for writing";
      end if;
      FAccess := new File'(FD => Fd);
      return FAccess;
   end Open_Write;

   function Open_Append (Path : String) return File_Access is
      P       : Interfaces.C.Strings.chars_ptr :=
        Interfaces.C.Strings.New_String (Path);
      Fd      : Interfaces.C.int;
      FAccess : File_Access;
   begin
      Fd :=
        sys_fcntl_h.open
          (P,
           Interfaces.C.int
             (Mod_Int (sys_fcntl_h.O_WRONLY)
              or Mod_Int (sys_fcntl_h.O_CREAT)
              or Mod_Int (sys_fcntl_h.O_APPEND)));
      Interfaces.C.Strings.Free (P);
      if Integer (Fd) < 0 then
         raise Program_Error with "Failed to open file for appending";
      end if;
      FAccess := new File'(FD => Fd);
      return FAccess;
   end Open_Append;

   procedure Close (File : in out File_Access) is
      R : Interfaces.C.int;
   begin
      if File /= null then
         R := unistd_h.close (File.FD);
         if R < 0 then
            raise Program_Error with "Failed to close file";
         end if;

         File := null; -- Set to null after closing to avoid dangling pointer

      end if;
   end Close;

   procedure Read
     (File : File_Access; Buffer : in out Bytes; Count : out Natural)
   is
      Fd         : constant Interfaces.C.int := File.FD;
      Bytes_Read : sys_utypes_ussize_t_h.ssize_t;
   begin
      Bytes_Read := unistd_h.read (Fd, Buffer'Address, Buffer'Length);
      if Bytes_Read < 0 then
         raise Program_Error with "Failed to read from file";
      else
         --  Ada.Text_IO.Put_Line
         --    ("Read "
         --     & sys_utypes_ussize_t_h.ssize_t'Image (Bytes_Read)
         --     & " bytes from file with FD: "
         --     & Interfaces.C.int'Image (Fd));
         Count := Natural (Bytes_Read);
      end if;
   end Read;

   procedure Write (File : File_Access; Buffer : Bytes; Count : out Natural) is
      Fd            : constant Interfaces.C.int := File.FD;
      Bytes_Written : sys_utypes_ussize_t_h.ssize_t;
   begin
      Bytes_Written := unistd_h.write (Fd, Buffer'Address, Buffer'Length);
      if Bytes_Written < 0 then
         raise Program_Error with "Failed to write to file";
      end if;
      Count := Natural (Bytes_Written);
   end Write;

   procedure Wake_On_IO
     (Sched_Cx : Scheduler.Sched_Cx_Access; File : File_Access)
   is
      -- This procedure is a placeholder for waking up the scheduler on IO events.
      -- The actual implementation would depend on the scheduler's design.
   begin
      -- Here we would typically register the file descriptor with the scheduler
      -- to wake up when IO is ready. This is a no-op in this example.
      --  Ada.Text_IO.Put_Line
      --    ("Waking up scheduler for IO on file descriptor: "
      --     & Interfaces.C.Int'Image (File.all.FD));
      Scheduler.Wake_On_IO_Read (Sched_Cx, File.all.FD);
   end;
end Scheduler.IO.File;
