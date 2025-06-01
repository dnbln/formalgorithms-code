with SPARK.Containers.Formal;

package body scheduler is
    Local_Worker_Queue_Size_Total : constant Natural := 256;
    type Local_Worker_Queue_Idx is new Natural range 1..Local_Worker_Queue_Size_Total;

    protected type Worker_Task_Queue is
        entry Push (f: Void_Fn);
    private
        Q : SPARK.Containers.Formal.Vectors;
    end Worker_Task_Queue;

    protected body Worker_Task_Queue is
        --  entry Push (f: Void_Fn)
        --  when 
        --  is
        --  begin
        --      null;
        --  end Push;
    end Worker_Task_Queue;

    task type Worker_Task is
        entry Start (f: access function return T);
    end Worker_Task;

    task body Worker_Task is
        f: access function return T;
    begin
        accept Start (f: access function return T) do
            
        end Start;
    end Worker_Task;

    function Spawn_RT_And_Block_On(f: Fn) return T is
        Result : T;

        type Void_Fn is access procedure;

        Workers : array (1 .. 4) of Worker_Task;
    begin
        Workers(1).Start(f);

        -- Wait for all workers to complete
        for I in Workers'Range loop
            accept Workers(I).Start do
                Result := f.all;  -- Assuming f is a function that returns T
            end accept;
        end loop;

        return Result;
    end Spawn_RT_And_Block_On;
end scheduler;