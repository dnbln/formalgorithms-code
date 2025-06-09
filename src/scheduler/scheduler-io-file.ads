with Interfaces.C;

package Scheduler.IO.File is
   type File is private;
   type File_Access is access all File;

   function Open_Read (Path : String) return File_Access;
   function Open_Write (Path : String) return File_Access;
   function Open_Append (Path : String) return File_Access;

   procedure Advise_Read_Sequencial (File : in out File_Access);

   procedure Close (File : in out File_Access);

   procedure Read
     (File : File_Access; Buffer : in out Bytes; Count : out Natural)
   with Pre => Buffer'Length >= Count;
   -- Read Count bytes from File into Buffer.
   -- Buffer'Length must be at least Count.
   procedure Write (File : File_Access; Buffer : Bytes; Count : out Natural);

   procedure Wake_On_IO
     (Sched_Cx : Scheduler.Sched_Cx_Access; File : File_Access);
private
   type File is record
      FD : Interfaces.C.int;  -- File descriptor or handle
   end record;
end Scheduler.IO.File;
