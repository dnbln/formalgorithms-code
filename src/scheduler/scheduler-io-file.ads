package Scheduler.IO.File is
   type File is private;
   type File_Access is access all File;

   function Open_Read (Path : String) return File;
   function Open_Write (Path : String) return File;
   procedure Close (File : in out File);

   procedure Read
     (File : in out File; Buffer : in out Bytes; Count : out Positive)
   with Pre => Buffer'Length >= Count;
   -- Read Count bytes from File into Buffer.
   -- Buffer'Length must be at least Count.
   procedure Write (File : in out File; Buffer : Bytes);

   procedure Wake_On_IO (Sched_Cx : Scheduler.Sched_Cx_Access; File : File);
private
   type File is record
      FD : Integer;  -- File descriptor or handle
   end record;
end Scheduler.IO.File;
