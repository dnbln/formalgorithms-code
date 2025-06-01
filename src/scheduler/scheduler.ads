package scheduler is
    generic
        type T is private;
        type Fn is access function return T;
    function Spawn_RT_And_Block_On(f: Fn) return T;
end scheduler;