----------------------------- MODULE scheduler -----------------------------
EXTENDS Naturals, Integers, TLC, Sequences

CONSTANT GQSize
CONSTANT LQSize
CONSTANT NumWorkers
CONSTANT NumFutures
CONSTANT NumFutureSteps
CONSTANT KQPollNum
CONSTANT NullTask
CONSTANT NullLock
CONSTANT NullFuture
CONSTANT NullKQ
CONSTANT NullBlockedIOInfoType
CONSTANT NullFB
CONSTANT NullFD
CONSTANT NullTRA
CONSTANT NumClockCyclesBeforeGQPushPull

ASSUME GQSize >= 8
ASSUME LQSize >= 4
ASSUME NumWorkers >= 1
ASSUME NumFutures >= 1
ASSUME NumFutures <= 10000
ASSUME KQPollNum >= 1
ASSUME NumClockCyclesBeforeGQPushPull >= 1

GQ == 1..GQSize
LQ == 1..LQSize
Workers == 1..NumWorkers
OptWorker == 0..NumWorkers
KQ == 0..NumWorkers

ClkCycleSingleType == 0..NumClockCyclesBeforeGQPushPull
ClkCyclesType == [Workers -> ClkCycleSingleType]

ASSUME NullLock \notin Workers

Task_Id == Nat

TaskPusherProcesses == NumWorkers + 1 .. NumWorkers * 2

RootFuture == NumWorkers * 2 + 1
OtherFutures == RootFuture + 1 .. RootFuture + NumFutures - 1
AllFutures == RootFuture..RootFuture + NumFutures - 1
KernelProcessId == RootFuture + NumFutures + 1
TimeKeeperProcId == KernelProcessId + 1

FDs == 0..NumFutures-1

TSReady == "ready"
TSRunning == "running"
TSBTimer == "blocked_timer"
TSBIO == "blocked_io"
TSCompleted == "completed"
TSCancelled == "cancelled"
TaskState == {TSReady, TSRunning, TSBTimer, TSBIO, TSCompleted, TSCancelled}

\** Synchronization of Future processes, for polling
FSNew == "future_sync_new"
FSPolling == "future_sync_polling"
FSReturned == "future_sync_returned"
FSCompleted == "future_sync_completed"
FutureSync == {FSNew, FSPolling, FSReturned, FSCompleted}

FuturesListType == [AllFutures -> FutureSync]
FutureRefType == Nat
ASSUME NullFuture \notin FutureRefType
FutureOptRefType == FutureRefType \union {NullFuture}
FuturePushType == [Workers -> FutureOptRefType]

BlockedIOKindRead == "read"
BlockedIOKindWrite == "write"
BlockedIOKindType == {BlockedIOKindRead, BlockedIOKindWrite}

BlockedIOInfoType == [fd : FDs, ty : BlockedIOKindType, data: Nat, eof : BOOLEAN]
ASSUME NullBlockedIOInfoType \notin BlockedIOInfoType 
BlockedIOInfoOptType == BlockedIOInfoType \union {NullBlockedIOInfoType}

Task == [ t_id : Task_Id, state : TaskState, future : AllFutures, blocked_io_info : BlockedIOInfoOptType ]
ASSUME NullTask \notin Task  
OptTask == Task \union {NullTask}

LQLocalType == [LQ -> OptTask]
LQGlobalType == [Workers -> LQLocalType]
LQSizesType == [Workers -> 0..LQSize]
LQClocksType == [Workers -> 0..LQSize + 1]

LQLockType == Workers \union {NullLock}
LQLocksType == [Workers -> LQLockType]

GQType == [GQ -> OptTask]
GQLockType == Workers \union {NullLock}

KQWaitKindRead == "read"
KQWaitKindWrite == "write"
KQWaitKind == {KQWaitKindRead, KQWaitKindWrite}

ASSUME KQWaitKind = BlockedIOKindType

KEventType == [ fd : FDs, kind : KQWaitKind, data : Nat, eof : BOOLEAN, t_id : Task_Id ]
KQType == [available : Seq(KEventType), waiting : Seq(KEventType)]
ASSUME NullKQ \notin KQType
KQOptType == KQType \union {NullKQ}
KQueuesType == [KQ -> KQOptType]

ESeq == [i \in 1..0 |-> TRUE]
NewKQ == [available |-> ESeq, waiting |-> ESeq]

MinNum(a, b) == IF a < b THEN a ELSE b

FBKindRead == "read"
FBKindWrite == "write"
FBKindTimer == "timer"
FBKindType == {FBKindRead, FBKindWrite, FBKindTimer}
ASSUME NullFD \notin FDs
OptFDType == FDs \union {NullFD}
FBType == [kind : FBKindType, fd : OptFDType]
ASSUME NullFB \notin FBType
OptFBType == FBType \union {NullFB}
FBListType == [AllFutures -> OptFBType]
FutureWorkesListType == [AllFutures -> OptWorker]
ASSUME NullTRA \notin Nat
NatOrNullTRA == Nat \union {NullTRA}
TaskReadyAgesType == Seq(NatOrNullTRA)

SeqToSet(s) == { s[i] : i ∈ DOMAIN s }

(* --algorithm scheduler

variables
    \** Global queue
    GQA = [p \in GQ |-> NullTask]; \* Global active queue
    GQAFirst = 0; \* Global active queue first
    GQALast = 0; \* Global active queue last
    GQB = [p \in GQ |-> NullTask]; \* Global blocked queue
    GQBSize = 0; \* Global blocked queue size
    GQPPPointer = 0; \* Global queue push / pull pointer
    
    GQLock = NullLock; \* Lock for the global queue
    
    \** Local queues
    LQA = [w \in Workers |-> [p \in LQ |-> NullTask]]; \* Local active queues
    LQAClock = [w \in Workers |-> 0]; \* Local active queue clock indexes
    ClkCycles = [w \in Workers |-> 0]; \* Count of clock cycles since last gq push / pull
    LQASizes = [w \in Workers |-> 0]; \* Local active queue sizes
    LQB = [w \in Workers |-> [p \in LQ |-> NullTask]]; \* Local blocked queues
    LQBSizes = [w \in Workers |-> 0]; \* Local blocked queue sizes
    
    LQLocks = [w \in Workers |-> NullLock]; \* Locks for the local queues
    
    \** Task id generator
    TaskIdCurrent = 0; \* Task id generator current
    TasksFinished = 0; \* Task id generator number of tasks finished
    
    RTStarted = FALSE; \* set to TRUE when the runtime initialized and the worker threads can start
    RTStopped = FALSE; \* set to TRUE when all tasks are done, according to TasksFinished 
    Futures = [f \in AllFutures |-> FSNew]; \* Futures, for synchronization. Futures are their own processes, `Poll` is an await in that process
    FuturePush = [w \in Workers |-> NullFuture]; \* Futures to spawn, implements `Spawn(Sch_Cx, Future)` from Ada in a separate process
    
    FuturesBlocked = [f \in AllFutures |-> NullFB];
    FutureWorkers = [f \in AllFutures |-> 0];
    
    FDReadsAvailable = [fd \in FDs |-> 0]; \* TCP listener: number of sockets available, and for sockets: number of bytes available to read
    FDWritesAvailable = [fd \in FDs |-> 0]; \* TCP listener: 0, sockets: number of bytes available in kernel buffers, writing more than this will force the kernel to flush
    KQueues = [kq \in KQ |-> NullKQ]; \* KQueues
    
    TaskReadyAges = ESeq;
    RoundRobinToken = 1;
    
define
    AllTasksDone == RTStarted = TRUE /\ TaskIdCurrent = TasksFinished
    AllWorkersFinished == 
        /\ \A t \in Workers: pc[t] = "Done"
        /\ \A t \in TaskPusherProcesses: pc[t] = "Done"
    WorkersStopOnceRTFlags == RTStopped => <>AllWorkersFinished
    RTStopFlaggedOnceAllTasksDone == AllTasksDone => <>RTStopped
    EventuallyAllTasksFinish == <>AllTasksDone
    NoNullTasksInFrontOfLQAClock == \A w \in Workers: \A p \in 1..LQAClock[w] - 1: LQA[w][p] # NullTask
    AllNullTasksAfterDone ==
        /\ \A w \in Workers: (LQASizes[w] = 0 /\ LQBSizes[w] = 0 /\ \A p \in LQ: (LQA[w][p] = NullTask /\ LQB[w][p] = NullTask))
        /\ (GQAFirst = GQALast /\ GQBSize = 0 /\ \A p \in GQ: GQA[p] = NullTask /\ GQB[p] = NullTask)
    NoDuplicateTasks ==
        /\ \A w1, w2 \in Workers: (LQLocks[w1] = NullLock /\ LQLocks[w2] = NullLock) => \A p1, p2 \in LQ: (w1 # w2) \/ (w1 = w2 /\ p1 # p2) => (LQA[w1][p1] # NullTask /\ LQA[w2][p2] # NullTask => LQA[w1][p1].t_id # LQA[w2][p2].t_id)
    GlobalQueueActiveReady == \A p \in GQAFirst + 1 .. GQALast: GQA[p] # NullTask /\ GQA[p].state = TSReady
    QBFDIs(T, kind, fd) == T # NullTask /\ T.state = TSBIO /\ T.blocked_io_info.fd = fd /\ T.blocked_io_info.ty = kind
    KQHasFd(Q, kind, fd) == Len(SelectSeq(Q.waiting \o Q.available, LAMBDA x: x.fd = fd /\ x.kind = kind)) = 1 
    BlockedInKQueue ==
        /\ \A w \in Workers: LQLocks[w] = NullLock /\ KQueues[w] # NullKQ => (\A fd \in FDs: \A kind \in BlockedIOKindType: (\E p \in LQ: QBFDIs(LQB[w][p], kind, fd)) <=> KQHasFd(KQueues[w], kind, fd))
        /\ (GQLock = NullLock /\ KQueues[0] # NullKQ => (\A fd \in FDs: \A kind \in BlockedIOKindType: (\E p \in GQ: QBFDIs(GQB[p], kind, fd)) <=> KQHasFd(KQueues[0], kind, fd)))
    TaskReadyAgesHasProperLength == Len(TaskReadyAges) = TaskIdCurrent
    ReadyTasksAlwaysHaveNaturalAges ==
        /\ \A w \in Workers: \A i \in LQ: LQA[w][i] # NullTask /\ LQA[w][i].state = TSReady => TaskReadyAges[LQA[w][i].t_id] >= 0
        /\ \A i \in GQAFirst + 1 .. GQALast: TaskReadyAges[GQA[i].t_id] >= 0
    BlockedTasksHaveAgeMinusOne ==
        /\ \A w \in Workers: \A i \in LQ: LQA[w][i] # NullTask /\ LQA[w][i].state \in {TSBIO, TSBTimer} => TaskReadyAges[LQA[w][i].t_id] = NullTRA
        /\ \A w \in Workers: \A i \in LQ: LQB[w][i] # NullTask /\ LQB[w][i].state \in {TSBIO, TSBTimer} => TaskReadyAges[LQB[w][i].t_id] = NullTRA
        /\ \A i \in GQ: GQB[i] # NullTask => TaskReadyAges[GQB[i].t_id] < 0
        
    GQAFirstSmallerThanLast == GQAFirst <= GQALast
    GQASizesDoNotOverflow == (GQAFirst < GQALast => GQALast <= GQAFirst + GQSize)
    
    GQPPPointerProper == GQPPPointer \in GQAFirst..GQALast
    
    PollingFuturesHaveAssociatedWorkers == \A f \in AllFutures: (Futures[f] = FSPolling => FutureWorkers[f] \in Workers)
    RRTokenInWorkers == RoundRobinToken \in Workers
    
    TaskReadyAgesIsBounded == \A t \in 1..TaskIdCurrent: TaskReadyAges[t] # NullTRA => TaskReadyAges[t] <= (NumClockCyclesBeforeGQPushPull + 1) * NumWorkers * (TaskIdCurrent - TasksFinished)
    
    Safety ==
        /\ GQAFirstSmallerThanLast
        /\ GQASizesDoNotOverflow
        /\ GQPPPointerProper
        /\ GlobalQueueActiveReady
        /\ TasksFinished <= TaskIdCurrent
        /\ PollingFuturesHaveAssociatedWorkers
        /\ NoNullTasksInFrontOfLQAClock
        /\ NoDuplicateTasks
        /\ BlockedInKQueue
        /\ TaskReadyAgesHasProperLength
        /\ ReadyTasksAlwaysHaveNaturalAges
        /\ BlockedTasksHaveAgeMinusOne
        /\ RRTokenInWorkers
        /\ TaskReadyAgesIsBounded
    
    Liveness ==
        /\ WorkersStopOnceRTFlags
        /\ RTStopFlaggedOnceAllTasksDone
        /\ EventuallyAllTasksFinish
        /\ AllTasksDone => <>AllNullTasksAfterDone

    TypeInvariant ==
        /\ GQA \in GQType
        /\ GQAFirst \in 0..GQSize * 2
        /\ GQALast \in 0..GQSize * 2
        /\ GQB \in GQType
        /\ GQBSize \in 0..GQSize
        /\ GQLock \in GQLockType
        /\ LQA \in LQGlobalType
        /\ LQAClock \in LQClocksType
        /\ ClkCycles \in ClkCyclesType
        /\ LQASizes \in LQSizesType
        /\ LQB \in LQGlobalType
        /\ LQBSizes \in LQSizesType
        /\ LQLocks \in LQLocksType
        /\ TaskIdCurrent \in Nat
        /\ TasksFinished \in Nat
        /\ RTStarted \in BOOLEAN
        /\ RTStopped \in BOOLEAN
        /\ Futures \in FuturesListType
        /\ FuturePush \in FuturePushType
        /\ FuturesBlocked \in FBListType
        /\ FutureWorkers \in FutureWorkesListType
        /\ KQueues \in KQueuesType
        /\ TaskReadyAges \in TaskReadyAgesType
end define;

macro Next_TId(var) begin
    TaskIdCurrent := TaskIdCurrent + 1;
    TaskReadyAges := Append(TaskReadyAges, 0);
    var := TaskIdCurrent;
end macro;
\*
\*procedure Push_LQA_Have_Lock(task, wr)
\*variables
\*    I = 0;
\*begin
\*    CheckLQSize:
\*    if LQASizes[wr] = LQSize then
\*        LockGQ:
\*            await GQLock = NullLock;
\*            GQLock := wr;
\*            I := LQSize \div 2 + 1;
\*        PushGQLoop:
\*            while I < LQSize do
\*            PushGQStatusCheck:
\*                if LQA[wr][I] # NullTask then
\*                PushTaskNotNull:
\*                    if LQA[wr][I].state = TSReady then
\*                        GQALast := GQALast + 1;
\*                        GQA[(GQALast % GQSize) + 1] := LQA[wr][I];
\*                        LQA[wr][I] := NullTask;
\*                    elsif LQA[wr][I].state \in {TSBTimer, TSBIO} then
\*                            GQBSize := GQBSize + 1;
\*                            GQB[GQBSize] := LQA[wr][I];
\*                            LQA[wr][I] := NullTask;
\*                            if KQueues[0] = NullKQ then
\*                                KQueues[0] := NewKQ;
\*                            end if;
\*                            PushGQPushToKQ:
\*                                if GQB[GQBSize].state = TSBIO then
\*                                    KQueues[0].waiting := Append (KQueues[0].waiting, [ fd |-> GQB[GQBSize].blocked_io_info.fd, kind |-> GQB[GQBSize].blocked_io_info.ty, data |-> 0, eof |-> FALSE, t_id |-> GQB[GQBSize].t_id ]);
\*                                end if;
\*                    end if;
\*                end if;
\*            GQPushWhileStep:
\*                I := I + 1;
\*            end while;
\*        UnlockGQ:
\*            GQLock := NullLock;
\*            LQASizes[wr] := LQSize \div 2;
\*        CheckClock:
\*            if LQAClock[wr] > LQASizes[wr] then
\*                LQASizes[wr] := LQASizes[wr] + 1;
\*                LQA[wr] := [LQA[wr] EXCEPT ![LQASizes[wr]] = LQA[wr][LQAClock[wr]], ![LQAClock[wr]] = NullTask];
\*                LQAClock[wr] := LQASizes[wr];
\*            end if;
\*    end if;
\*    PushLQ:
\*    LQASizes[wr] := LQASizes[wr] + 1; 
\*    LQA[wr][LQASizes[wr]] := task;
\*    return;
\*end procedure;

fair+ process RTSpawn = 0
variables
    tid = 0;
begin
    RTGetNext:
        Next_TId(tid);
    RTSpawnInit:
        \* No need to lock here, workers await RTStarted which we only set on the next step.
        LQA[1][1] := [ t_id |-> tid, state |-> TSReady, future |-> RootFuture, blocked_io_info |-> NullBlockedIOInfoType ];
        LQASizes[1] := 1;
    RTStart:
        RTStarted := TRUE;
    RTFinish:
        await TaskIdCurrent = TasksFinished;
        RTStopped := TRUE;
end process;

fair+ process WorkerThread \in Workers
variables
    task = NullTask;
    HasWork = FALSE;
    I = 1;
    J = 1;
    K = 1;
    L = 1;
    kq_out = ESeq;
    current_time = 0;
    lqbuf = [p \in LQ |-> NullTask];
begin
    WWait:
        await RTStarted = TRUE;
        
    Main_Loop:
        while TRUE do
            \* stop condition if coming from main scheduler thread
            RTStopCheck:
                if RTStopped = TRUE \/ TasksFinished = TaskIdCurrent then
                    goto WFinish;
                end if;
            Kernel:
                either
                    FDReadsAvailable := [x \in DOMAIN FDReadsAvailable |-> FDReadsAvailable[x] + 64];
                    FDWritesAvailable := [x \in DOMAIN FDWritesAvailable |-> FDWritesAvailable[x] + 16];
                or
                    FDReadsAvailable := [x \in DOMAIN FDReadsAvailable |-> IF x % 2 = 0 THEN FDReadsAvailable[x] + 64 ELSE FDReadsAvailable[x]];
                    FDWritesAvailable := [x \in DOMAIN FDWritesAvailable |-> IF x % 2 = 1 THEN FDWritesAvailable[x] + 16 ELSE FDWritesAvailable[x]];
                or
                    FDReadsAvailable := [x \in DOMAIN FDReadsAvailable |-> IF x % 2 = 1 THEN FDReadsAvailable[x] + 64 ELSE FDReadsAvailable[x]];
                    FDWritesAvailable := [x \in DOMAIN FDWritesAvailable |-> IF x % 2 = 0 THEN FDWritesAvailable[x] + 16 ELSE FDWritesAvailable[x]];
                end either;
                KQueues := [kq \in DOMAIN KQueues |->
                    IF KQueues[kq] = NullKQ
                    THEN NullKQ
                    ELSE LET
                        IndUpd == [p \in DOMAIN KQueues[kq].waiting |-> [index |-> p, data |->
                            (CASE KQueues[kq].waiting[p].kind = KQWaitKindRead -> FDReadsAvailable[KQueues[kq].waiting[p].fd]
                              [] KQueues[kq].waiting[p].kind = KQWaitKindWrite -> FDWritesAvailable[KQueues[kq].waiting[p].fd]) ]]
                    IN [waiting |-> [p \in DOMAIN KQueues[kq].waiting \ {IndUpd[p].index : p \in DOMAIN IndUpd} |-> KQueues[kq].waiting[p]],
                        available |->
                            KQueues[kq].available \o [p \in DOMAIN IndUpd |-> [KQueues[kq].waiting[IndUpd[p].index] EXCEPT !.data = IndUpd[p].data, !.eof = FALSE]]]
                ];
            \* process qb
            ProcessQB_LQ_Lock:
                await LQLocks[self] = NullLock;
                LQLocks[self] := self;
                
                \* Flush Blocked
                I := 1;
                K := 0;
            LQ_Flush_Loop:
                while I <= LQASizes[self] do
                LQ_Flush_Loop_Inner:
                    if LQA[self][I] = NullTask then
                        goto LQ_Flush_Step;
                    end if;
                LQ_Flush_Continue:
                    if LQA[self][I].state = TSReady then
                        K := K + 1;
                        LQA[self][K] := LQA[self][I];
                        LQ_Flush_Remove_From_Old:
                        if I # K then
                            LQA[self][I] := NullTask;
                        end if;
                    elsif LQA[self][I].state \in {TSBTimer, TSBIO} then
                        \* Flush to GQB
                        if LQBSizes[self] = LQSize then
                            LQ_Flush_To_GQB:
                                J := 1;
                            LQ_Flush_To_GQBLoop1:
                                while J <= LQSize \div 2 do
                                    GQBSize := GQBSize + 1;
                                    GQB[GQBSize] := LQB[self][J];
                                    LQ_Flush_To_GQBLoop1_Check_KQ:
                                        if KQueues[0] = NullKQ then
                                            KQueues[0] := NewKQ;
                                        end if;
                                    LQ_Flush_To_GQBLoop1_Add_To_KQ:    
                                    KQueues[0].waiting := Append (KQueues[0].waiting, [ fd |-> LQB[self][J].blocked_io_info.fd, kind |-> LQB[self][J].blocked_io_info.ty, data |-> 0, eof |-> FALSE, t_id |-> LQB[self][J].t_id ]);
                                    J := J + 1;
                                end while;
                            LQ_Flush_To_GQB2:
                                J := 1;
                            LQ_Flush_To_GQBLoop2:
                                while J <= LQSize \div 2 do
                                    if LQB[self][J].state = TSBIO then
                                        KQueues[self].waiting := SelectSeq (KQueues[self].waiting, LAMBDA w: w.fd # LQB[self][J].blocked_io_info.fd \/ w.kind # LQB[self][J].blocked_io_info.ty);
                                    end if;
                                    LQ_Flush_To_GQBLoop2AfterCheckContinuation:
                                    LQB[self][J] := LQB[self][J + LQSize \div 2];
                                    J := J + 1;
                                end while;
                            LQBSizes[self] := LQSize \div 2;
                        end if;
                        Flush_To_LQB_Continuation:
                        LQBSizes[self] := LQBSizes[self] + 1;
                        LQB[self][LQBSizes[self]] := LQA[self][I];
                        LQ_Push_TO_KQ_Check_Create:
                            if KQueues[self] = NullKQ then
                                KQueues[self] := NewKQ;
                            end if;
                        LQ_Push_TO_KQ_Push:
                            if LQA[self][I].state = TSBIO then
                                KQueues[self].waiting := Append (KQueues[self].waiting, [ fd |-> LQA[self][I].blocked_io_info.fd, kind |-> LQA[self][I].blocked_io_info.ty, data |-> 0, eof |-> FALSE, t_id |-> LQA[self][I].t_id ]);
                            end if;
                        LQ_Push_TO_KQ_Push_Cont:
                            LQA[self][I] := NullTask;
                    end if;
                LQ_Flush_Step:
                    I := I + 1;
                end while;
                LQASizes[self] := K;
            LQ_GQ_CheckPushPull:
                ClkCycles[self] := ClkCycles[self] + 1;
                if ClkCycles[self] = NumClockCyclesBeforeGQPushPull then
                Begin_LQ_GQ_PushPull:
                    ClkCycles[self] := 0;
                    AttemptEnqueueFromGlobalLockGQ2:
                        await GQLock = NullLock;
                        GQLock := self;
                    GQ_Poll_Check_KQ2:
                        if KQueues[0] = NullKQ then
                            goto GQ_Flush_Ready_Begin2;
                        end if;
                    GQ_Poll_KQ_Begin2:
                        kq_out := SubSeq(KQueues[0].available, 1, MinNum(KQPollNum, Len(KQueues[0].available)));
                        KQueues[0].available := IF KQPollNum < Len(KQueues[0].available)
                                                THEN SubSeq(KQueues[0].available, KQPollNum + 1, Len(KQueues[0].available))
                                                ELSE ESeq;
                    GQ_Update_Ready2:
                        GQB := [i \in GQ |->
                            IF i \in 1..GQBSize /\ \E x \in DOMAIN kq_out: GQB[self][i].t_id = kq_out[x].t_id THEN
                                LET x == CHOOSE x \in DOMAIN kq_out: kq_out[x].t_id = LQB[i].t_id
                                IN 
                                    [LQB[i] EXCEPT
                                        !.state = TSReady,
                                        !.blocked_io_info.data = kq_out[x].data,
                                        !.blocked_io_info.eof = kq_out[x].eof
                                    ]
                            ELSE GQB[i]];
                    GQ_Flush_Ready_Begin2:
                        I := 1;
                        K := 0;
                    GQ_Flush_Ready2:
                        while I <= GQBSize do
                            GQ_Flush_Check_Timer2:
                                if GQB[I].state = TSBTimer then
                                    either
                                        GQB[I].state := TSReady; \* Timer finished
                                    or
                                        skip; \* Timer didn't finish
                                    end either;
                                end if;
                            GQ_Flush_Ready_Check_Ready2:
                                if GQB[I].state = TSReady then
                                    \* Push to GQA
                                    GQALast := GQALast + 1;
                                    GQA[((GQALast - 1) % GQSize) + 1] := GQB[I];
                                    TaskReadyAges[GQB[I].t_id] := 0;
                                else
                                    K := K + 1;
                                    GQB[K] := GQB[I];
                                end if;
                            GQ_Flush_Ready_Step2:
                                I := I + 1;
                        end while;
                    GQ_Flush_Ready_Done2:
                        GQBSize := K;
                        I := GQAFirst + 1;
                        K := 0;
                    AttemptEnqueueFromGlobalWhile2:
                        while I <= GQALast /\ K < (LQSize \div 2) do
                            K := K + 1;
                            LQA[self][K] := GQA[I]; \* INV: GQA[first+1..last] always not null
                            I := I + 1;
                        end while;
                    UpdateGQAPointers2:
                        GQAFirst := I - 1;
                    UpdateGQAPointersCheck2:                        
                        if GQAFirst > GQSize then
                            GQAFirst := GQAFirst - GQSize;
                            GQALast := GQALast - GQSize;
                            GQPPPointer := GQPPPointer - GQSize;
                        end if;
                    PushPullBegin:
                        GQPPPointer := IF GQPPPointer <= GQAFirst THEN GQAFirst + 1 ELSE GQPPPointer + 1;
                        I := GQPPPointer;
                        K := 1;
                        PerformFirstPushPull:
                            if GQPPPointer <= GQALast /\ K <= LQASizes[self] then
                                task := LQA[K];
                                LQA[K] := GQA[((GQPPPointer - 1) % GQ) + 1];
                                GQA[((GQPPPointer - 1) % GQ) + 1] := task;
                                GQPPPointer := IF GQPPPointer < GQALast THEN GQPPPointer + 1 ELSE GQAFirst + 1;
                                K := K + 1;
                            else
                                goto AttemptEnqueueFromGlobalFinish2;
                            end if;
                    PushPull:
                        while GQPPPointer # I /\ K <= LQASizes[self] do
                            PerformPushPull:
                                task := LQA[K];
                                LQA[K] := GQA[((GQPPPointer - 1) % GQ) + 1];
                                GQA[((GQPPPointer - 1) % GQ) + 1] := task;
                            PushPullStep:
                                GQPPPointer := IF GQPPPointer < GQALast THEN GQPPPointer + 1 ELSE GQAFirst + 1;
                                K := K + 1;
                        end while;
                    AttemptEnqueueFromGlobalFinish2:
                        GQLock := NullLock;
                end if;
            LQ_Poll_KQ:
                if KQueues[self] # NullKQ then
                    LQ_Poll_KQ_Begin:
                        kq_out := SubSeq(KQueues[self].available, 1, MinNum(KQPollNum, Len(KQueues[self].available)));
                        KQueues[self].available :=  IF KQPollNum < Len(KQueues[self].available)
                                                    THEN SubSeq(KQueues[self].available, KQPollNum + 1, Len(KQueues[self].available))
                                                    ELSE ESeq;
                    Update_Ready:
                        LQB[self] := [i \in LQ |->
                            IF i \in 1..LQBSizes[self] /\ \E x \in DOMAIN kq_out: LQB[self][i].t_id = kq_out[x].t_id THEN
                                LET x == CHOOSE x \in DOMAIN kq_out: kq_out[x].t_id = LQB[self][i].t_id
                                IN 
                                    [LQB[self][i] EXCEPT
                                        !.state = TSReady,
                                        !.blocked_io_info.data = kq_out[x].data,
                                        !.blocked_io_info.eof = kq_out[x].eof
                                    ]
                            ELSE LQB[self][i]];
                end if;
                Flush_Ready_Begin:
                    I := 1;
                    K := 0;
                Flush_Ready:
                    while I <= LQBSizes[self] do
                        Flush_Check_Timer:
                            if LQB[self][I].state = TSBTimer then
                                either
                                    LQB[self][I].state := TSReady; \* Timer finished
                                or
                                    skip; \* Timer didn't finish
                                end either;
                            end if;
                        Flush_Ready_Check_Ready:
                            if LQB[self][I].state = TSReady then
                                \* Push to LQA
                                CheckLQSize:
                                if LQASizes[self] = LQSize then
                                    LockGQ:
                                        await GQLock = NullLock;
                                        GQLock := self;
                                        L := LQSize \div 2 + 1;
                                    PushGQLoop:
                                        while L < LQSize do
                                        PushGQStatusCheck:
                                            if LQA[self][L] # NullTask then
                                            PushTaskNotNull:
                                                if LQA[self][L].state = TSReady then
                                                    GQALast := GQALast + 1;
                                                    GQA[((GQALast - 1) % GQSize) + 1] := LQA[self][L];
                                                    LQA[self][L] := NullTask;
                                                elsif LQA[self][L].state \in {TSBTimer, TSBIO} then
                                                        GQBSize := GQBSize + 1;
                                                        GQB[GQBSize] := LQA[self][L];
                                                        LQA[self][L] := NullTask;
                                                        if KQueues[0] = NullKQ then
                                                            KQueues[0] := NewKQ;
                                                        end if;
                                                        PushGQPushToKQ:
                                                            if GQB[GQBSize].state = TSBIO then
                                                                KQueues[0].waiting := Append (KQueues[0].waiting, [ fd |-> GQB[GQBSize].blocked_io_info.fd, kind |-> GQB[GQBSize].blocked_io_info.ty, data |-> 0, eof |-> FALSE, t_id |-> GQB[GQBSize].t_id ]);
                                                            end if;
                                                end if;
                                            end if;
                                        GQPushWhileStep:
                                            L := L + 1;
                                        end while;
                                    UnlockGQ:
                                        GQLock := NullLock;
                                        LQASizes[self] := LQSize \div 2;
                                    CheckClock:
                                        if LQAClock[self] > LQASizes[self] then
                                            LQASizes[self] := LQASizes[self] + 1;
                                            LQA[self] := [LQA[self] EXCEPT ![LQASizes[self]] = LQA[self][LQAClock[self]], ![LQAClock[self]] = NullTask];
                                            LQAClock[self] := LQASizes[self];
                                        end if;
                                end if;
                                PushLQ:
                                LQASizes[self] := LQASizes[self] + 1; 
                                LQA[self][LQASizes[self]] := LQB[self][I];
                                TaskReadyAges[LQA[self][LQASizes[self]].t_id] := 0;
                            else
                                K := K + 1;
                                LQB[self][K] := LQB[self][I];
                                if I # K then
                                    Flush_Ready_Check_Ready_Move_Old:
                                    LQB[self][I] := NullTask;
                                end if;
                            end if;
                        Flush_Ready_Step:
                            I := I + 1;
                    end while;
                Flush_Ready_Done:
                    LQBSizes[self] := K;
            LQ_Reset_Clock:
                LQAClock[self] := LQASizes[self] + 1;
                \* fetch next task (opt)
            LQ_Pull:
                if LQASizes[self] = 0 then
                    HasWork := FALSE;
                else
                    LQAClock[self] := LQAClock[self] - 1;
                    LQA[self][LQAClock[self]].state := TSRunning;
                    task := LQA[self][LQAClock[self]];
                    HasWork := TRUE;
                end if;
            LQ_Unlock:
                LQLocks[self] := NullLock;
            CheckHasWork:
                if HasWork = FALSE then
                    \* enqueue from other queues
                    \** Global
                    AttemptEnqueueFromGlobalLockLQ:
                        await LQLocks[self] = NullLock;
                        LQLocks[self] := self;
                        K := 0;
                    AttemptEnqueueFromGlobalLockGQ:
                        await GQLock = NullLock;
                        GQLock := self;
                    GQ_Poll_Check_KQ:
                        if KQueues[0] = NullKQ then
                            goto GQ_Flush_Ready_Begin;
                        end if;
                    GQ_Poll_KQ_Begin:
                        kq_out := SubSeq(KQueues[0].available, 1, MinNum(KQPollNum, Len(KQueues[0].available)));
                        KQueues[0].available := IF KQPollNum < Len(KQueues[0].available)
                                                THEN SubSeq(KQueues[0].available, KQPollNum + 1, Len(KQueues[0].available))
                                                ELSE ESeq;
                    GQ_Update_Ready:
                        GQB := [i \in GQ |->
                            IF i \in 1..GQBSize /\ \E x \in DOMAIN kq_out: GQB[self][i].t_id = kq_out[x].t_id THEN
                                LET x == CHOOSE x \in DOMAIN kq_out: kq_out[x].t_id = LQB[i].t_id
                                IN 
                                    [LQB[i] EXCEPT
                                        !.state = TSReady,
                                        !.blocked_io_info.data = kq_out[x].data,
                                        !.blocked_io_info.eof = kq_out[x].eof
                                    ]
                            ELSE GQB[i]];
                    GQ_Flush_Ready_Begin:
                        I := 1;
                        K := 0;
                    GQ_Flush_Ready:
                        while I <= GQBSize do
                            GQ_Flush_Check_Timer:
                                if GQB[I].state = TSBTimer then
                                    either
                                        GQB[I].state := TSReady; \* Timer finished
                                    or
                                        skip; \* Timer didn't finish
                                    end either;
                                end if;
                            GQ_Flush_Ready_Check_Ready:
                                if GQB[I].state = TSReady then
                                    \* Push to GQA
                                    GQALast := GQALast + 1;
                                    GQA[((GQALast - 1) % GQSize) + 1] := GQB[I];
                                    TaskReadyAges[GQB[I].t_id] := 0;
                                else
                                    K := K + 1;
                                    GQB[K] := GQB[I];
                                end if;
                            GQ_Flush_Ready_Step:
                                I := I + 1;
                        end while;
                    GQ_Flush_Ready_Done:
                        GQBSize := K;
                        I := GQAFirst + 1;
                        K := 0;
                    AttemptEnqueueFromGlobalWhile:
                        while I <= GQALast /\ K < (LQSize \div 2) do
                            K := K + 1;
                            LQA[self][K] := GQA[I]; \* INV: GQA[first+1..last] always not null
                            I := I + 1;
                        end while;
                    UpdateGQAPointers:
                        GQAFirst := I - 1;
                    UpdateGQAPointersCheck:                        
                        if GQAFirst > GQSize then
                            GQAFirst := GQAFirst - GQSize;
                            GQALast := GQALast - GQSize;
                            GQPPPointer := GQPPPointer - GQSize;
                        end if;
                    AttemptEnqueueFromGlobalFinish:
                        GQLock := NullLock;
                        LQASizes[self] := K;
                        LQLocks[self] := NullLock;
                    EnqueueFromGlobalCheck:
                        if K > 0 then
                            goto Main_Loop;
                        end if;
                    WorkStealingBegin:
                        I := 1;
                    WorkStealingMainLoop:
                        while I <= NumWorkers do
                            if I < self then
                                WorkStealingAcquireSelfLock:
                                    await LQLocks[self] = NullLock;
                                    LQLocks[self] := self;
                                WorkStealingAcquireVictimLock:
                                await LQLocks[I] = NullLock;
                                LQLocks[I] := self;
                                WorkstealingCheck1:
                                    if LQASizes[I] < 2 then
                                        goto WorkStealingFinishedStolen1;
                                    end if;
                                WorkStealingCont1:
                                J := LQAClock[I] + 1;
                                K := 0;
                                WorkstealingSteal:
                                    while J < LQASizes[I] do
                                        if LQA[I][J] # NullTask /\ LQA[I][J].state = TSReady then
                                            K := K + 1;
                                            LQA := [LQA EXCEPT ![self][K] = LQA[I][J], ![I][J] = NullTask];
                                            if K > LQASizes[I] \div 2 then
                                                goto WorkStealingFinishedStolen1;
                                            end if;
                                        end if;
                                    end while;
                                WorkStealingFinishedStolen1:
                                    LQLocks := [LQLocks EXCEPT ![I] = NullLock, ![self] = NullLock];
                                    LQASizes[self] := K;
                                    LQAClock[self] := K + 1;
                            elsif I > self then
                                WorkStealingAcquireVictimLock2:
                                await LQLocks[I] = NullLock;
                                LQLocks[I] := self;
                                WorkstealingCheck2:
                                    if LQASizes[I] < 2 then
                                        goto WorkStealingUnlockVictimLock2;
                                    end if;
                                WorkStealingCont2:
                                J := LQAClock[I] + 1;
                                K := 0;
                                WorkstealingSteal2:
                                    while J < LQASizes[I] do
                                        if LQA[I][J] # NullTask /\ LQA[I][J].state = TSReady then
                                            K := K + 1;
                                            lqbuf[K] := LQA[I][J];
                                            LQA[I][J] := NullTask;
                                            if K > LQASizes[I] \div 2 then
                                                goto WorkStealingUnlockVictimLock2;
                                            end if;
                                        end if;
                                    end while;
                                WorkStealingUnlockVictimLock2:
                                    LQLocks[I] := NullLock;
                                    LQA[self] := lqbuf;
                                    LQASizes[self] := K;
                                    LQAClock[self] := K + 1;
                            end if;
                        WorkStealingFinishedStolen:
                            if K > 0 then
                                goto Main_Loop;
                            end if;
                        WorkStealingLoopStep:
                            I := I + 1;
                        end while;
                    No_Tasks:
                        goto Main_Loop;
                else
                    Has_Work_Loop:
                        while HasWork = TRUE do
                            DoFuturePoll:
                                await RoundRobinToken = self; \* Aquire RR token
                                TaskReadyAges := [x \in DOMAIN TaskReadyAges |-> IF TaskReadyAges[x] = NullTRA THEN NullTRA ELSE TaskReadyAges[x] + 1]; \* Poll task
                                RoundRobinToken := IF self + 1 \in Workers THEN self + 1 ELSE 1; \* release RR token
                                \* Poll future
                                FutureWorkers[task.future] := self;
                                FuturesBlocked[task.future] := NullFB;
                                Futures[task.future] := FSPolling;
                            ProcessStatus:
                                await Futures[task.future] # FSPolling;
                            ProcessStatusInLQ:
                                await LQLocks[self] = NullLock;
                                LQLocks[self] := self;
                                if Futures[task.future] = FSReturned then
                                    if FuturesBlocked[task.future] # NullFB then
                                        if FuturesBlocked[task.future].kind \in {FBKindRead, FBKindWrite} then
                                            LQA[self][LQAClock[self]] := [LQA[self][LQAClock[self]] EXCEPT !.state = TSBIO, !.blocked_io_info = [fd |-> FuturesBlocked[task.future].fd, ty |-> FuturesBlocked[task.future].kind, data |-> 0, eof |-> FALSE]];
                                            TaskReadyAges[LQA[self][LQAClock[self]].t_id] := NullTRA;
                                        elsif FuturesBlocked[task.future].kind = FBKindTimer then
                                            LQA[self][LQAClock[self]] := [LQA[self][LQAClock[self]] EXCEPT !.state = TSBTimer];
                                            TaskReadyAges[LQA[self][LQAClock[self]].t_id] := NullTRA;
                                        end if;
                                    else
                                        LQA[self][LQAClock[self]].state := TSReady;
                                        TaskReadyAges[LQA[self][LQAClock[self]].t_id] := 0;
                                    end if;
                                else
                                    TaskReadyAges[LQA[self][LQAClock[self]].t_id] := NullTRA;
                                    LQA[self][LQAClock[self]] := NullTask;
                                    TasksFinished := TasksFinished + 1;
                                end if;
                            LQ_Unlock_AfterProc:
                                LQLocks[self] := NullLock;
                                \* Fetch next task
                            LQ_Lock2:
                                await LQLocks[self] = NullLock;
                                LQLocks[self] := self;
                            LQ_Pull2:
                                if LQASizes[self] = 0 then
                                    LQ_Pull_Empty2:
                                        HasWork := FALSE;
                                else
                                    UpdateLQAClock2:
                                        if LQAClock[self] = 1 then
                                            HasWork := FALSE;
                                            LQLocks[self] := NullLock; \* unlock
                                            goto Has_Work_Loop; \* exit
                                        end if;
                                    IncrementLQAClocK2:
                                        LQAClock[self] := LQAClock[self] - 1;
                                        LQA[self][LQAClock[self]].state := TSRunning;
                                        task := LQA[self][LQAClock[self]];
                                        HasWork := TRUE;
                                end if;
                            LQ_Unlock2:
                                LQLocks[self] := NullLock;
                        end while;
                end if;
        end while;
    WFinish:
        skip;
end process;

fair+ process TaskPusherProcess \in TaskPusherProcesses
variables
    wr = self - NumWorkers;
    tid = 0;
    I = 1;
begin
    TPPLoop:
        while TRUE do
            TPPStart:
                await FuturePush[wr] # NullFuture \/ RTStopped;
                if RTStopped then
                    goto TPPDone;
                else
                    Next_TId(tid);
                end if;
            TPPLockLQ:
                await LQLocks[wr] = NullLock;
                LQLocks[wr] := wr;
                CheckLQSize:
                if LQASizes[wr] = LQSize then
                    LockGQ:
                        await GQLock = NullLock;
                        GQLock := wr;
                        I := LQSize \div 2 + 1;
                    PushGQLoop:
                        while I < LQSize do
                        PushGQStatusCheck:
                            if LQA[wr][I] # NullTask then
                            PushTaskNotNull:
                                if LQA[wr][I].state = TSReady then
                                    GQALast := GQALast + 1;
                                    GQA[((GQALast - 1) % GQSize) + 1] := LQA[wr][I];
                                    LQA[wr][I] := NullTask;
                                elsif LQA[wr][I].state \in {TSBTimer, TSBIO} then
                                        GQBSize := GQBSize + 1;
                                        GQB[GQBSize] := LQA[wr][I];
                                        LQA[wr][I] := NullTask;
                                        if KQueues[0] = NullKQ then
                                            KQueues[0] := NewKQ;
                                        end if;
                                        PushGQPushToKQ:
                                            if GQB[GQBSize].state = TSBIO then
                                                KQueues[0].waiting := Append (KQueues[0].waiting, [ fd |-> GQB[GQBSize].blocked_io_info.fd, kind |-> GQB[GQBSize].blocked_io_info.ty, data |-> 0, eof |-> FALSE, t_id |-> GQB[GQBSize].t_id ]);
                                            end if;
                                end if;
                            end if;
                        GQPushWhileStep:
                            I := I + 1;
                        end while;
                    UnlockGQ:
                        GQLock := NullLock;
                        LQASizes[wr] := LQSize \div 2;
                    CheckClock:
                        if LQAClock[wr] > LQASizes[wr] then
                            LQASizes[wr] := LQASizes[wr] + 1;
                            LQA[wr] := [LQA[wr] EXCEPT ![LQASizes[wr]] = LQA[wr][LQAClock[wr]], ![LQAClock[wr]] = NullTask];
                            LQAClock[wr] := LQASizes[wr];
                        end if;
                end if;
            PushLQ:
                LQASizes[wr] := LQASizes[wr] + 1; 
                LQA[wr][LQASizes[wr]] := [t_id |-> tid, state |-> TSReady, future |-> FuturePush[wr], blocked_io_info |-> NullBlockedIOInfoType];
            TPPReleaseLockLQAndClearFuture:
                LQLocks[wr] := NullLock;
                FuturePush[wr] := NullFuture;
        end while;
    TPPDone:
        skip;
end process;


\*** End of scheduler

\*** From here on, we describe the client code, e.g. the code that interacts with the scheduler.

\*** These proesses are fair because any errors they might throw are catched by the worker threads, around the `.Poll` call
fair+ process RF \in {RootFuture}
variables
    fildes = 0;
    Steps = 0;
begin
    RootFutureAwaitStarted:
        await Futures[self] = FSPolling \/ RTStopped = TRUE;
        if RTStopped = TRUE then
            goto RootFutureDone;
        end if;
    RootFutureStarted:
        while Steps < NumFutures - 1 do
            Steps := Steps + 1;
            SpawnFuture:
                await FuturePush[FutureWorkers[self]] = NullFuture;
                FuturePush[FutureWorkers[self]] := RootFuture + Steps;
            SpawnFutureWaitFinish:
                await FuturePush[FutureWorkers[self]] = NullFuture;
        end while;
    RootFutureDone:
        Futures[self] := FSCompleted;
end process;

fair+ process OtherF \in OtherFutures
variables
    fildes = self - RootFuture;
    Steps = 0;
    PolledRead = FALSE;
begin
    OtherFutureStarted:
        while Steps < NumFutureSteps do
            AwaitInLoop:
            await Futures[self] = FSPolling \/ RTStopped = TRUE;
            if RTStopped = TRUE then
                goto OtherFutureDone;
            end if;
            OtherFutureContinue:
            Steps := Steps + 1;
            either
                FuturesBlocked[self] := [kind |-> FBKindRead, fd |-> fildes];
                PolledRead := TRUE;

                \* An await point
                Futures[self] := FSReturned;
                Cont1:
                    await Futures[self] = FSPolling;
            or
                FuturesBlocked[self] := [kind |-> FBKindWrite, fd |-> fildes];
                Futures[self] := FSReturned;
                Cont2:
                    await Futures[self] = FSPolling;
            or
                FuturesBlocked[self] := [kind |-> FBKindTimer, fd |-> NullFD];
                Futures[self] := FSReturned;
                Cont3:
                    await Futures[self] = FSPolling;
            or
                if PolledRead = TRUE then
                    FDReadsAvailable[fildes] := FDReadsAvailable[fildes] - 16;
                    PolledRead := FALSE;
                end if;
                Futures[self] := FSReturned;
                Cont4:
                    await Futures[self] = FSPolling;
            or
                Futures[self] := FSReturned; \* keep task as ready
                Cont5:
                    await Futures[self] = FSPolling;      
            or
                goto OtherFutureDone;
            end either;
        end while;
    OtherFutureDone:
        Futures[self] := FSCompleted;
end process;



\*** End of client code

end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "9fcff08e" /\ chksum(tla) = "f87e0d80")
\* Label CheckLQSize of process WorkerThread at line 581 col 33 changed to CheckLQSize_
\* Label LockGQ of process WorkerThread at line 583 col 41 changed to LockGQ_
\* Label PushGQLoop of process WorkerThread at line 587 col 41 changed to PushGQLoop_
\* Label PushGQStatusCheck of process WorkerThread at line 589 col 45 changed to PushGQStatusCheck_
\* Label PushTaskNotNull of process WorkerThread at line 591 col 49 changed to PushTaskNotNull_
\* Label PushGQPushToKQ of process WorkerThread at line 603 col 61 changed to PushGQPushToKQ_
\* Label GQPushWhileStep of process WorkerThread at line 609 col 45 changed to GQPushWhileStep_
\* Label UnlockGQ of process WorkerThread at line 612 col 41 changed to UnlockGQ_
\* Label CheckClock of process WorkerThread at line 615 col 41 changed to CheckClock_
\* Label PushLQ of process WorkerThread at line 622 col 33 changed to PushLQ_
\* Process variable tid of process RTSpawn at line 317 col 5 changed to tid_
\* Process variable I of process WorkerThread at line 336 col 5 changed to I_
\* Process variable fildes of process RF at line 948 col 5 changed to fildes_
\* Process variable Steps of process RF at line 949 col 5 changed to Steps_
VARIABLES pc, GQA, GQAFirst, GQALast, GQB, GQBSize, GQPPPointer, GQLock, LQA, 
          LQAClock, ClkCycles, LQASizes, LQB, LQBSizes, LQLocks, 
          TaskIdCurrent, TasksFinished, RTStarted, RTStopped, Futures, 
          FuturePush, FuturesBlocked, FutureWorkers, FDReadsAvailable, 
          FDWritesAvailable, KQueues, TaskReadyAges, RoundRobinToken

(* define statement *)
AllTasksDone == RTStarted = TRUE /\ TaskIdCurrent = TasksFinished
AllWorkersFinished ==
    /\ \A t \in Workers: pc[t] = "Done"
    /\ \A t \in TaskPusherProcesses: pc[t] = "Done"
WorkersStopOnceRTFlags == RTStopped => <>AllWorkersFinished
RTStopFlaggedOnceAllTasksDone == AllTasksDone => <>RTStopped
EventuallyAllTasksFinish == <>AllTasksDone
NoNullTasksInFrontOfLQAClock == \A w \in Workers: \A p \in 1..LQAClock[w] - 1: LQA[w][p] # NullTask
AllNullTasksAfterDone ==
    /\ \A w \in Workers: (LQASizes[w] = 0 /\ LQBSizes[w] = 0 /\ \A p \in LQ: (LQA[w][p] = NullTask /\ LQB[w][p] = NullTask))
    /\ (GQAFirst = GQALast /\ GQBSize = 0 /\ \A p \in GQ: GQA[p] = NullTask /\ GQB[p] = NullTask)
NoDuplicateTasks ==
    /\ \A w1, w2 \in Workers: (LQLocks[w1] = NullLock /\ LQLocks[w2] = NullLock) => \A p1, p2 \in LQ: (w1 # w2) \/ (w1 = w2 /\ p1 # p2) => (LQA[w1][p1] # NullTask /\ LQA[w2][p2] # NullTask => LQA[w1][p1].t_id # LQA[w2][p2].t_id)
GlobalQueueActiveReady == \A p \in GQAFirst + 1 .. GQALast: GQA[p] # NullTask /\ GQA[p].state = TSReady
QBFDIs(T, kind, fd) == T # NullTask /\ T.state = TSBIO /\ T.blocked_io_info.fd = fd /\ T.blocked_io_info.ty = kind
KQHasFd(Q, kind, fd) == Len(SelectSeq(Q.waiting \o Q.available, LAMBDA x: x.fd = fd /\ x.kind = kind)) = 1
BlockedInKQueue ==
    /\ \A w \in Workers: LQLocks[w] = NullLock /\ KQueues[w] # NullKQ => (\A fd \in FDs: \A kind \in BlockedIOKindType: (\E p \in LQ: QBFDIs(LQB[w][p], kind, fd)) <=> KQHasFd(KQueues[w], kind, fd))
    /\ (GQLock = NullLock /\ KQueues[0] # NullKQ => (\A fd \in FDs: \A kind \in BlockedIOKindType: (\E p \in GQ: QBFDIs(GQB[p], kind, fd)) <=> KQHasFd(KQueues[0], kind, fd)))
TaskReadyAgesHasProperLength == Len(TaskReadyAges) = TaskIdCurrent
ReadyTasksAlwaysHaveNaturalAges ==
    /\ \A w \in Workers: \A i \in LQ: LQA[w][i] # NullTask /\ LQA[w][i].state = TSReady => TaskReadyAges[LQA[w][i].t_id] >= 0
    /\ \A i \in GQAFirst + 1 .. GQALast: TaskReadyAges[GQA[i].t_id] >= 0
BlockedTasksHaveAgeMinusOne ==
    /\ \A w \in Workers: \A i \in LQ: LQA[w][i] # NullTask /\ LQA[w][i].state \in {TSBIO, TSBTimer} => TaskReadyAges[LQA[w][i].t_id] = NullTRA
    /\ \A w \in Workers: \A i \in LQ: LQB[w][i] # NullTask /\ LQB[w][i].state \in {TSBIO, TSBTimer} => TaskReadyAges[LQB[w][i].t_id] = NullTRA
    /\ \A i \in GQ: GQB[i] # NullTask => TaskReadyAges[GQB[i].t_id] < 0

GQAFirstSmallerThanLast == GQAFirst <= GQALast
GQASizesDoNotOverflow == (GQAFirst < GQALast => GQALast <= GQAFirst + GQSize)

GQPPPointerProper == GQPPPointer \in GQAFirst..GQALast

PollingFuturesHaveAssociatedWorkers == \A f \in AllFutures: (Futures[f] = FSPolling => FutureWorkers[f] \in Workers)
RRTokenInWorkers == RoundRobinToken \in Workers

TaskReadyAgesIsBounded == \A t \in 1..TaskIdCurrent: TaskReadyAges[t] # NullTRA => TaskReadyAges[t] <= (NumClockCyclesBeforeGQPushPull + 1) * NumWorkers * (TaskIdCurrent - TasksFinished)

Safety ==
    /\ GQAFirstSmallerThanLast
    /\ GQASizesDoNotOverflow
    /\ GQPPPointerProper
    /\ GlobalQueueActiveReady
    /\ TasksFinished <= TaskIdCurrent
    /\ PollingFuturesHaveAssociatedWorkers
    /\ NoNullTasksInFrontOfLQAClock
    /\ NoDuplicateTasks
    /\ BlockedInKQueue
    /\ TaskReadyAgesHasProperLength
    /\ ReadyTasksAlwaysHaveNaturalAges
    /\ BlockedTasksHaveAgeMinusOne
    /\ RRTokenInWorkers
    /\ TaskReadyAgesIsBounded

Liveness ==
    /\ WorkersStopOnceRTFlags
    /\ RTStopFlaggedOnceAllTasksDone
    /\ EventuallyAllTasksFinish
    /\ AllTasksDone => <>AllNullTasksAfterDone

TypeInvariant ==
    /\ GQA \in GQType
    /\ GQAFirst \in 0..GQSize * 2
    /\ GQALast \in 0..GQSize * 2
    /\ GQB \in GQType
    /\ GQBSize \in 0..GQSize
    /\ GQLock \in GQLockType
    /\ LQA \in LQGlobalType
    /\ LQAClock \in LQClocksType
    /\ ClkCycles \in ClkCyclesType
    /\ LQASizes \in LQSizesType
    /\ LQB \in LQGlobalType
    /\ LQBSizes \in LQSizesType
    /\ LQLocks \in LQLocksType
    /\ TaskIdCurrent \in Nat
    /\ TasksFinished \in Nat
    /\ RTStarted \in BOOLEAN
    /\ RTStopped \in BOOLEAN
    /\ Futures \in FuturesListType
    /\ FuturePush \in FuturePushType
    /\ FuturesBlocked \in FBListType
    /\ FutureWorkers \in FutureWorkesListType
    /\ KQueues \in KQueuesType
    /\ TaskReadyAges \in TaskReadyAgesType

VARIABLES tid_, task, HasWork, I_, J, K, L, kq_out, current_time, lqbuf, wr, 
          tid, I, fildes_, Steps_, fildes, Steps, PolledRead

vars == << pc, GQA, GQAFirst, GQALast, GQB, GQBSize, GQPPPointer, GQLock, LQA, 
           LQAClock, ClkCycles, LQASizes, LQB, LQBSizes, LQLocks, 
           TaskIdCurrent, TasksFinished, RTStarted, RTStopped, Futures, 
           FuturePush, FuturesBlocked, FutureWorkers, FDReadsAvailable, 
           FDWritesAvailable, KQueues, TaskReadyAges, RoundRobinToken, tid_, 
           task, HasWork, I_, J, K, L, kq_out, current_time, lqbuf, wr, tid, 
           I, fildes_, Steps_, fildes, Steps, PolledRead >>

ProcSet == {0} \cup (Workers) \cup (TaskPusherProcesses) \cup ({RootFuture}) \cup (OtherFutures)

Init == (* Global variables *)
        /\ GQA = [p \in GQ |-> NullTask]
        /\ GQAFirst = 0
        /\ GQALast = 0
        /\ GQB = [p \in GQ |-> NullTask]
        /\ GQBSize = 0
        /\ GQPPPointer = 0
        /\ GQLock = NullLock
        /\ LQA = [w \in Workers |-> [p \in LQ |-> NullTask]]
        /\ LQAClock = [w \in Workers |-> 0]
        /\ ClkCycles = [w \in Workers |-> 0]
        /\ LQASizes = [w \in Workers |-> 0]
        /\ LQB = [w \in Workers |-> [p \in LQ |-> NullTask]]
        /\ LQBSizes = [w \in Workers |-> 0]
        /\ LQLocks = [w \in Workers |-> NullLock]
        /\ TaskIdCurrent = 0
        /\ TasksFinished = 0
        /\ RTStarted = FALSE
        /\ RTStopped = FALSE
        /\ Futures = [f \in AllFutures |-> FSNew]
        /\ FuturePush = [w \in Workers |-> NullFuture]
        /\ FuturesBlocked = [f \in AllFutures |-> NullFB]
        /\ FutureWorkers = [f \in AllFutures |-> 0]
        /\ FDReadsAvailable = [fd \in FDs |-> 0]
        /\ FDWritesAvailable = [fd \in FDs |-> 0]
        /\ KQueues = [kq \in KQ |-> NullKQ]
        /\ TaskReadyAges = ESeq
        /\ RoundRobinToken = 1
        (* Process RTSpawn *)
        /\ tid_ = 0
        (* Process WorkerThread *)
        /\ task = [self \in Workers |-> NullTask]
        /\ HasWork = [self \in Workers |-> FALSE]
        /\ I_ = [self \in Workers |-> 1]
        /\ J = [self \in Workers |-> 1]
        /\ K = [self \in Workers |-> 1]
        /\ L = [self \in Workers |-> 1]
        /\ kq_out = [self \in Workers |-> ESeq]
        /\ current_time = [self \in Workers |-> 0]
        /\ lqbuf = [self \in Workers |-> [p \in LQ |-> NullTask]]
        (* Process TaskPusherProcess *)
        /\ wr = [self \in TaskPusherProcesses |-> self - NumWorkers]
        /\ tid = [self \in TaskPusherProcesses |-> 0]
        /\ I = [self \in TaskPusherProcesses |-> 1]
        (* Process RF *)
        /\ fildes_ = [self \in {RootFuture} |-> 0]
        /\ Steps_ = [self \in {RootFuture} |-> 0]
        (* Process OtherF *)
        /\ fildes = [self \in OtherFutures |-> self - RootFuture]
        /\ Steps = [self \in OtherFutures |-> 0]
        /\ PolledRead = [self \in OtherFutures |-> FALSE]
        /\ pc = [self \in ProcSet |-> CASE self = 0 -> "RTGetNext"
                                        [] self \in Workers -> "WWait"
                                        [] self \in TaskPusherProcesses -> "TPPLoop"
                                        [] self \in {RootFuture} -> "RootFutureAwaitStarted"
                                        [] self \in OtherFutures -> "OtherFutureStarted"]

RTGetNext == /\ pc[0] = "RTGetNext"
             /\ TaskIdCurrent' = TaskIdCurrent + 1
             /\ TaskReadyAges' = Append(TaskReadyAges, 0)
             /\ tid_' = TaskIdCurrent'
             /\ pc' = [pc EXCEPT ![0] = "RTSpawnInit"]
             /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, GQPPPointer, 
                             GQLock, LQA, LQAClock, ClkCycles, LQASizes, LQB, 
                             LQBSizes, LQLocks, TasksFinished, RTStarted, 
                             RTStopped, Futures, FuturePush, FuturesBlocked, 
                             FutureWorkers, FDReadsAvailable, 
                             FDWritesAvailable, KQueues, RoundRobinToken, task, 
                             HasWork, I_, J, K, L, kq_out, current_time, lqbuf, 
                             wr, tid, I, fildes_, Steps_, fildes, Steps, 
                             PolledRead >>

RTSpawnInit == /\ pc[0] = "RTSpawnInit"
               /\ LQA' = [LQA EXCEPT ![1][1] = [ t_id |-> tid_, state |-> TSReady, future |-> RootFuture, blocked_io_info |-> NullBlockedIOInfoType ]]
               /\ LQASizes' = [LQASizes EXCEPT ![1] = 1]
               /\ pc' = [pc EXCEPT ![0] = "RTStart"]
               /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                               GQPPPointer, GQLock, LQAClock, ClkCycles, LQB, 
                               LQBSizes, LQLocks, TaskIdCurrent, TasksFinished, 
                               RTStarted, RTStopped, Futures, FuturePush, 
                               FuturesBlocked, FutureWorkers, FDReadsAvailable, 
                               FDWritesAvailable, KQueues, TaskReadyAges, 
                               RoundRobinToken, tid_, task, HasWork, I_, J, K, 
                               L, kq_out, current_time, lqbuf, wr, tid, I, 
                               fildes_, Steps_, fildes, Steps, PolledRead >>

RTStart == /\ pc[0] = "RTStart"
           /\ RTStarted' = TRUE
           /\ pc' = [pc EXCEPT ![0] = "RTFinish"]
           /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, GQPPPointer, 
                           GQLock, LQA, LQAClock, ClkCycles, LQASizes, LQB, 
                           LQBSizes, LQLocks, TaskIdCurrent, TasksFinished, 
                           RTStopped, Futures, FuturePush, FuturesBlocked, 
                           FutureWorkers, FDReadsAvailable, FDWritesAvailable, 
                           KQueues, TaskReadyAges, RoundRobinToken, tid_, task, 
                           HasWork, I_, J, K, L, kq_out, current_time, lqbuf, 
                           wr, tid, I, fildes_, Steps_, fildes, Steps, 
                           PolledRead >>

RTFinish == /\ pc[0] = "RTFinish"
            /\ TaskIdCurrent = TasksFinished
            /\ RTStopped' = TRUE
            /\ pc' = [pc EXCEPT ![0] = "Done"]
            /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, GQPPPointer, 
                            GQLock, LQA, LQAClock, ClkCycles, LQASizes, LQB, 
                            LQBSizes, LQLocks, TaskIdCurrent, TasksFinished, 
                            RTStarted, Futures, FuturePush, FuturesBlocked, 
                            FutureWorkers, FDReadsAvailable, FDWritesAvailable, 
                            KQueues, TaskReadyAges, RoundRobinToken, tid_, 
                            task, HasWork, I_, J, K, L, kq_out, current_time, 
                            lqbuf, wr, tid, I, fildes_, Steps_, fildes, Steps, 
                            PolledRead >>

RTSpawn == RTGetNext \/ RTSpawnInit \/ RTStart \/ RTFinish

WWait(self) == /\ pc[self] = "WWait"
               /\ RTStarted = TRUE
               /\ pc' = [pc EXCEPT ![self] = "Main_Loop"]
               /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                               GQPPPointer, GQLock, LQA, LQAClock, ClkCycles, 
                               LQASizes, LQB, LQBSizes, LQLocks, TaskIdCurrent, 
                               TasksFinished, RTStarted, RTStopped, Futures, 
                               FuturePush, FuturesBlocked, FutureWorkers, 
                               FDReadsAvailable, FDWritesAvailable, KQueues, 
                               TaskReadyAges, RoundRobinToken, tid_, task, 
                               HasWork, I_, J, K, L, kq_out, current_time, 
                               lqbuf, wr, tid, I, fildes_, Steps_, fildes, 
                               Steps, PolledRead >>

Main_Loop(self) == /\ pc[self] = "Main_Loop"
                   /\ pc' = [pc EXCEPT ![self] = "RTStopCheck"]
                   /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                   GQPPPointer, GQLock, LQA, LQAClock, 
                                   ClkCycles, LQASizes, LQB, LQBSizes, LQLocks, 
                                   TaskIdCurrent, TasksFinished, RTStarted, 
                                   RTStopped, Futures, FuturePush, 
                                   FuturesBlocked, FutureWorkers, 
                                   FDReadsAvailable, FDWritesAvailable, 
                                   KQueues, TaskReadyAges, RoundRobinToken, 
                                   tid_, task, HasWork, I_, J, K, L, kq_out, 
                                   current_time, lqbuf, wr, tid, I, fildes_, 
                                   Steps_, fildes, Steps, PolledRead >>

RTStopCheck(self) == /\ pc[self] = "RTStopCheck"
                     /\ IF RTStopped = TRUE \/ TasksFinished = TaskIdCurrent
                           THEN /\ pc' = [pc EXCEPT ![self] = "WFinish"]
                           ELSE /\ pc' = [pc EXCEPT ![self] = "Kernel"]
                     /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                     GQPPPointer, GQLock, LQA, LQAClock, 
                                     ClkCycles, LQASizes, LQB, LQBSizes, 
                                     LQLocks, TaskIdCurrent, TasksFinished, 
                                     RTStarted, RTStopped, Futures, FuturePush, 
                                     FuturesBlocked, FutureWorkers, 
                                     FDReadsAvailable, FDWritesAvailable, 
                                     KQueues, TaskReadyAges, RoundRobinToken, 
                                     tid_, task, HasWork, I_, J, K, L, kq_out, 
                                     current_time, lqbuf, wr, tid, I, fildes_, 
                                     Steps_, fildes, Steps, PolledRead >>

Kernel(self) == /\ pc[self] = "Kernel"
                /\ \/ /\ FDReadsAvailable' = [x \in DOMAIN FDReadsAvailable |-> FDReadsAvailable[x] + 64]
                      /\ FDWritesAvailable' = [x \in DOMAIN FDWritesAvailable |-> FDWritesAvailable[x] + 16]
                   \/ /\ FDReadsAvailable' = [x \in DOMAIN FDReadsAvailable |-> IF x % 2 = 0 THEN FDReadsAvailable[x] + 64 ELSE FDReadsAvailable[x]]
                      /\ FDWritesAvailable' = [x \in DOMAIN FDWritesAvailable |-> IF x % 2 = 1 THEN FDWritesAvailable[x] + 16 ELSE FDWritesAvailable[x]]
                   \/ /\ FDReadsAvailable' = [x \in DOMAIN FDReadsAvailable |-> IF x % 2 = 1 THEN FDReadsAvailable[x] + 64 ELSE FDReadsAvailable[x]]
                      /\ FDWritesAvailable' = [x \in DOMAIN FDWritesAvailable |-> IF x % 2 = 0 THEN FDWritesAvailable[x] + 16 ELSE FDWritesAvailable[x]]
                /\ KQueues' =            [kq \in DOMAIN KQueues |->
                                  IF KQueues[kq] = NullKQ
                                  THEN NullKQ
                                  ELSE LET
                                      IndUpd == [p \in DOMAIN KQueues[kq].waiting |-> [index |-> p, data |->
                                          (CASE KQueues[kq].waiting[p].kind = KQWaitKindRead -> FDReadsAvailable'[KQueues[kq].waiting[p].fd]
                                            [] KQueues[kq].waiting[p].kind = KQWaitKindWrite -> FDWritesAvailable'[KQueues[kq].waiting[p].fd]) ]]
                                  IN [waiting |-> [p \in DOMAIN KQueues[kq].waiting \ {IndUpd[p].index : p \in DOMAIN IndUpd} |-> KQueues[kq].waiting[p]],
                                      available |->
                                          KQueues[kq].available \o [p \in DOMAIN IndUpd |-> [KQueues[kq].waiting[IndUpd[p].index] EXCEPT !.data = IndUpd[p].data, !.eof = FALSE]]]
                              ]
                /\ pc' = [pc EXCEPT ![self] = "ProcessQB_LQ_Lock"]
                /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                GQPPPointer, GQLock, LQA, LQAClock, ClkCycles, 
                                LQASizes, LQB, LQBSizes, LQLocks, 
                                TaskIdCurrent, TasksFinished, RTStarted, 
                                RTStopped, Futures, FuturePush, FuturesBlocked, 
                                FutureWorkers, TaskReadyAges, RoundRobinToken, 
                                tid_, task, HasWork, I_, J, K, L, kq_out, 
                                current_time, lqbuf, wr, tid, I, fildes_, 
                                Steps_, fildes, Steps, PolledRead >>

ProcessQB_LQ_Lock(self) == /\ pc[self] = "ProcessQB_LQ_Lock"
                           /\ LQLocks[self] = NullLock
                           /\ LQLocks' = [LQLocks EXCEPT ![self] = self]
                           /\ I_' = [I_ EXCEPT ![self] = 1]
                           /\ K' = [K EXCEPT ![self] = 0]
                           /\ pc' = [pc EXCEPT ![self] = "LQ_Flush_Loop"]
                           /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                           GQBSize, GQPPPointer, GQLock, LQA, 
                                           LQAClock, ClkCycles, LQASizes, LQB, 
                                           LQBSizes, TaskIdCurrent, 
                                           TasksFinished, RTStarted, RTStopped, 
                                           Futures, FuturePush, FuturesBlocked, 
                                           FutureWorkers, FDReadsAvailable, 
                                           FDWritesAvailable, KQueues, 
                                           TaskReadyAges, RoundRobinToken, 
                                           tid_, task, HasWork, J, L, kq_out, 
                                           current_time, lqbuf, wr, tid, I, 
                                           fildes_, Steps_, fildes, Steps, 
                                           PolledRead >>

LQ_Flush_Loop(self) == /\ pc[self] = "LQ_Flush_Loop"
                       /\ IF I_[self] <= LQASizes[self]
                             THEN /\ pc' = [pc EXCEPT ![self] = "LQ_Flush_Loop_Inner"]
                                  /\ UNCHANGED LQASizes
                             ELSE /\ LQASizes' = [LQASizes EXCEPT ![self] = K[self]]
                                  /\ pc' = [pc EXCEPT ![self] = "LQ_GQ_CheckPushPull"]
                       /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                       GQPPPointer, GQLock, LQA, LQAClock, 
                                       ClkCycles, LQB, LQBSizes, LQLocks, 
                                       TaskIdCurrent, TasksFinished, RTStarted, 
                                       RTStopped, Futures, FuturePush, 
                                       FuturesBlocked, FutureWorkers, 
                                       FDReadsAvailable, FDWritesAvailable, 
                                       KQueues, TaskReadyAges, RoundRobinToken, 
                                       tid_, task, HasWork, I_, J, K, L, 
                                       kq_out, current_time, lqbuf, wr, tid, I, 
                                       fildes_, Steps_, fildes, Steps, 
                                       PolledRead >>

LQ_Flush_Loop_Inner(self) == /\ pc[self] = "LQ_Flush_Loop_Inner"
                             /\ IF LQA[self][I_[self]] = NullTask
                                   THEN /\ pc' = [pc EXCEPT ![self] = "LQ_Flush_Step"]
                                   ELSE /\ pc' = [pc EXCEPT ![self] = "LQ_Flush_Continue"]
                             /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                             GQBSize, GQPPPointer, GQLock, LQA, 
                                             LQAClock, ClkCycles, LQASizes, 
                                             LQB, LQBSizes, LQLocks, 
                                             TaskIdCurrent, TasksFinished, 
                                             RTStarted, RTStopped, Futures, 
                                             FuturePush, FuturesBlocked, 
                                             FutureWorkers, FDReadsAvailable, 
                                             FDWritesAvailable, KQueues, 
                                             TaskReadyAges, RoundRobinToken, 
                                             tid_, task, HasWork, I_, J, K, L, 
                                             kq_out, current_time, lqbuf, wr, 
                                             tid, I, fildes_, Steps_, fildes, 
                                             Steps, PolledRead >>

LQ_Flush_Continue(self) == /\ pc[self] = "LQ_Flush_Continue"
                           /\ IF LQA[self][I_[self]].state = TSReady
                                 THEN /\ K' = [K EXCEPT ![self] = K[self] + 1]
                                      /\ LQA' = [LQA EXCEPT ![self][K'[self]] = LQA[self][I_[self]]]
                                      /\ pc' = [pc EXCEPT ![self] = "LQ_Flush_Remove_From_Old"]
                                 ELSE /\ IF LQA[self][I_[self]].state \in {TSBTimer, TSBIO}
                                            THEN /\ IF LQBSizes[self] = LQSize
                                                       THEN /\ pc' = [pc EXCEPT ![self] = "LQ_Flush_To_GQB"]
                                                       ELSE /\ pc' = [pc EXCEPT ![self] = "Flush_To_LQB_Continuation"]
                                            ELSE /\ pc' = [pc EXCEPT ![self] = "LQ_Flush_Step"]
                                      /\ UNCHANGED << LQA, K >>
                           /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                           GQBSize, GQPPPointer, GQLock, 
                                           LQAClock, ClkCycles, LQASizes, LQB, 
                                           LQBSizes, LQLocks, TaskIdCurrent, 
                                           TasksFinished, RTStarted, RTStopped, 
                                           Futures, FuturePush, FuturesBlocked, 
                                           FutureWorkers, FDReadsAvailable, 
                                           FDWritesAvailable, KQueues, 
                                           TaskReadyAges, RoundRobinToken, 
                                           tid_, task, HasWork, I_, J, L, 
                                           kq_out, current_time, lqbuf, wr, 
                                           tid, I, fildes_, Steps_, fildes, 
                                           Steps, PolledRead >>

LQ_Flush_Remove_From_Old(self) == /\ pc[self] = "LQ_Flush_Remove_From_Old"
                                  /\ IF I_[self] # K[self]
                                        THEN /\ LQA' = [LQA EXCEPT ![self][I_[self]] = NullTask]
                                        ELSE /\ TRUE
                                             /\ LQA' = LQA
                                  /\ pc' = [pc EXCEPT ![self] = "LQ_Flush_Step"]
                                  /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                                  GQBSize, GQPPPointer, GQLock, 
                                                  LQAClock, ClkCycles, 
                                                  LQASizes, LQB, LQBSizes, 
                                                  LQLocks, TaskIdCurrent, 
                                                  TasksFinished, RTStarted, 
                                                  RTStopped, Futures, 
                                                  FuturePush, FuturesBlocked, 
                                                  FutureWorkers, 
                                                  FDReadsAvailable, 
                                                  FDWritesAvailable, KQueues, 
                                                  TaskReadyAges, 
                                                  RoundRobinToken, tid_, task, 
                                                  HasWork, I_, J, K, L, kq_out, 
                                                  current_time, lqbuf, wr, tid, 
                                                  I, fildes_, Steps_, fildes, 
                                                  Steps, PolledRead >>

Flush_To_LQB_Continuation(self) == /\ pc[self] = "Flush_To_LQB_Continuation"
                                   /\ LQBSizes' = [LQBSizes EXCEPT ![self] = LQBSizes[self] + 1]
                                   /\ LQB' = [LQB EXCEPT ![self][LQBSizes'[self]] = LQA[self][I_[self]]]
                                   /\ pc' = [pc EXCEPT ![self] = "LQ_Push_TO_KQ_Check_Create"]
                                   /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                                   GQBSize, GQPPPointer, 
                                                   GQLock, LQA, LQAClock, 
                                                   ClkCycles, LQASizes, 
                                                   LQLocks, TaskIdCurrent, 
                                                   TasksFinished, RTStarted, 
                                                   RTStopped, Futures, 
                                                   FuturePush, FuturesBlocked, 
                                                   FutureWorkers, 
                                                   FDReadsAvailable, 
                                                   FDWritesAvailable, KQueues, 
                                                   TaskReadyAges, 
                                                   RoundRobinToken, tid_, task, 
                                                   HasWork, I_, J, K, L, 
                                                   kq_out, current_time, lqbuf, 
                                                   wr, tid, I, fildes_, Steps_, 
                                                   fildes, Steps, PolledRead >>

LQ_Push_TO_KQ_Check_Create(self) == /\ pc[self] = "LQ_Push_TO_KQ_Check_Create"
                                    /\ IF KQueues[self] = NullKQ
                                          THEN /\ KQueues' = [KQueues EXCEPT ![self] = NewKQ]
                                          ELSE /\ TRUE
                                               /\ UNCHANGED KQueues
                                    /\ pc' = [pc EXCEPT ![self] = "LQ_Push_TO_KQ_Push"]
                                    /\ UNCHANGED << GQA, GQAFirst, GQALast, 
                                                    GQB, GQBSize, GQPPPointer, 
                                                    GQLock, LQA, LQAClock, 
                                                    ClkCycles, LQASizes, LQB, 
                                                    LQBSizes, LQLocks, 
                                                    TaskIdCurrent, 
                                                    TasksFinished, RTStarted, 
                                                    RTStopped, Futures, 
                                                    FuturePush, FuturesBlocked, 
                                                    FutureWorkers, 
                                                    FDReadsAvailable, 
                                                    FDWritesAvailable, 
                                                    TaskReadyAges, 
                                                    RoundRobinToken, tid_, 
                                                    task, HasWork, I_, J, K, L, 
                                                    kq_out, current_time, 
                                                    lqbuf, wr, tid, I, fildes_, 
                                                    Steps_, fildes, Steps, 
                                                    PolledRead >>

LQ_Push_TO_KQ_Push(self) == /\ pc[self] = "LQ_Push_TO_KQ_Push"
                            /\ IF LQA[self][I_[self]].state = TSBIO
                                  THEN /\ KQueues' = [KQueues EXCEPT ![self].waiting = Append (KQueues[self].waiting, [ fd |-> LQA[self][I_[self]].blocked_io_info.fd, kind |-> LQA[self][I_[self]].blocked_io_info.ty, data |-> 0, eof |-> FALSE, t_id |-> LQA[self][I_[self]].t_id ])]
                                  ELSE /\ TRUE
                                       /\ UNCHANGED KQueues
                            /\ pc' = [pc EXCEPT ![self] = "LQ_Push_TO_KQ_Push_Cont"]
                            /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                            GQBSize, GQPPPointer, GQLock, LQA, 
                                            LQAClock, ClkCycles, LQASizes, LQB, 
                                            LQBSizes, LQLocks, TaskIdCurrent, 
                                            TasksFinished, RTStarted, 
                                            RTStopped, Futures, FuturePush, 
                                            FuturesBlocked, FutureWorkers, 
                                            FDReadsAvailable, 
                                            FDWritesAvailable, TaskReadyAges, 
                                            RoundRobinToken, tid_, task, 
                                            HasWork, I_, J, K, L, kq_out, 
                                            current_time, lqbuf, wr, tid, I, 
                                            fildes_, Steps_, fildes, Steps, 
                                            PolledRead >>

LQ_Push_TO_KQ_Push_Cont(self) == /\ pc[self] = "LQ_Push_TO_KQ_Push_Cont"
                                 /\ LQA' = [LQA EXCEPT ![self][I_[self]] = NullTask]
                                 /\ pc' = [pc EXCEPT ![self] = "LQ_Flush_Step"]
                                 /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                                 GQBSize, GQPPPointer, GQLock, 
                                                 LQAClock, ClkCycles, LQASizes, 
                                                 LQB, LQBSizes, LQLocks, 
                                                 TaskIdCurrent, TasksFinished, 
                                                 RTStarted, RTStopped, Futures, 
                                                 FuturePush, FuturesBlocked, 
                                                 FutureWorkers, 
                                                 FDReadsAvailable, 
                                                 FDWritesAvailable, KQueues, 
                                                 TaskReadyAges, 
                                                 RoundRobinToken, tid_, task, 
                                                 HasWork, I_, J, K, L, kq_out, 
                                                 current_time, lqbuf, wr, tid, 
                                                 I, fildes_, Steps_, fildes, 
                                                 Steps, PolledRead >>

LQ_Flush_To_GQB(self) == /\ pc[self] = "LQ_Flush_To_GQB"
                         /\ J' = [J EXCEPT ![self] = 1]
                         /\ pc' = [pc EXCEPT ![self] = "LQ_Flush_To_GQBLoop1"]
                         /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                         GQPPPointer, GQLock, LQA, LQAClock, 
                                         ClkCycles, LQASizes, LQB, LQBSizes, 
                                         LQLocks, TaskIdCurrent, TasksFinished, 
                                         RTStarted, RTStopped, Futures, 
                                         FuturePush, FuturesBlocked, 
                                         FutureWorkers, FDReadsAvailable, 
                                         FDWritesAvailable, KQueues, 
                                         TaskReadyAges, RoundRobinToken, tid_, 
                                         task, HasWork, I_, K, L, kq_out, 
                                         current_time, lqbuf, wr, tid, I, 
                                         fildes_, Steps_, fildes, Steps, 
                                         PolledRead >>

LQ_Flush_To_GQBLoop1(self) == /\ pc[self] = "LQ_Flush_To_GQBLoop1"
                              /\ IF J[self] <= LQSize \div 2
                                    THEN /\ GQBSize' = GQBSize + 1
                                         /\ GQB' = [GQB EXCEPT ![GQBSize'] = LQB[self][J[self]]]
                                         /\ pc' = [pc EXCEPT ![self] = "LQ_Flush_To_GQBLoop1_Check_KQ"]
                                    ELSE /\ pc' = [pc EXCEPT ![self] = "LQ_Flush_To_GQB2"]
                                         /\ UNCHANGED << GQB, GQBSize >>
                              /\ UNCHANGED << GQA, GQAFirst, GQALast, 
                                              GQPPPointer, GQLock, LQA, 
                                              LQAClock, ClkCycles, LQASizes, 
                                              LQB, LQBSizes, LQLocks, 
                                              TaskIdCurrent, TasksFinished, 
                                              RTStarted, RTStopped, Futures, 
                                              FuturePush, FuturesBlocked, 
                                              FutureWorkers, FDReadsAvailable, 
                                              FDWritesAvailable, KQueues, 
                                              TaskReadyAges, RoundRobinToken, 
                                              tid_, task, HasWork, I_, J, K, L, 
                                              kq_out, current_time, lqbuf, wr, 
                                              tid, I, fildes_, Steps_, fildes, 
                                              Steps, PolledRead >>

LQ_Flush_To_GQBLoop1_Check_KQ(self) == /\ pc[self] = "LQ_Flush_To_GQBLoop1_Check_KQ"
                                       /\ IF KQueues[0] = NullKQ
                                             THEN /\ KQueues' = [KQueues EXCEPT ![0] = NewKQ]
                                             ELSE /\ TRUE
                                                  /\ UNCHANGED KQueues
                                       /\ pc' = [pc EXCEPT ![self] = "LQ_Flush_To_GQBLoop1_Add_To_KQ"]
                                       /\ UNCHANGED << GQA, GQAFirst, GQALast, 
                                                       GQB, GQBSize, 
                                                       GQPPPointer, GQLock, 
                                                       LQA, LQAClock, 
                                                       ClkCycles, LQASizes, 
                                                       LQB, LQBSizes, LQLocks, 
                                                       TaskIdCurrent, 
                                                       TasksFinished, 
                                                       RTStarted, RTStopped, 
                                                       Futures, FuturePush, 
                                                       FuturesBlocked, 
                                                       FutureWorkers, 
                                                       FDReadsAvailable, 
                                                       FDWritesAvailable, 
                                                       TaskReadyAges, 
                                                       RoundRobinToken, tid_, 
                                                       task, HasWork, I_, J, K, 
                                                       L, kq_out, current_time, 
                                                       lqbuf, wr, tid, I, 
                                                       fildes_, Steps_, fildes, 
                                                       Steps, PolledRead >>

LQ_Flush_To_GQBLoop1_Add_To_KQ(self) == /\ pc[self] = "LQ_Flush_To_GQBLoop1_Add_To_KQ"
                                        /\ KQueues' = [KQueues EXCEPT ![0].waiting = Append (KQueues[0].waiting, [ fd |-> LQB[self][J[self]].blocked_io_info.fd, kind |-> LQB[self][J[self]].blocked_io_info.ty, data |-> 0, eof |-> FALSE, t_id |-> LQB[self][J[self]].t_id ])]
                                        /\ J' = [J EXCEPT ![self] = J[self] + 1]
                                        /\ pc' = [pc EXCEPT ![self] = "LQ_Flush_To_GQBLoop1"]
                                        /\ UNCHANGED << GQA, GQAFirst, GQALast, 
                                                        GQB, GQBSize, 
                                                        GQPPPointer, GQLock, 
                                                        LQA, LQAClock, 
                                                        ClkCycles, LQASizes, 
                                                        LQB, LQBSizes, LQLocks, 
                                                        TaskIdCurrent, 
                                                        TasksFinished, 
                                                        RTStarted, RTStopped, 
                                                        Futures, FuturePush, 
                                                        FuturesBlocked, 
                                                        FutureWorkers, 
                                                        FDReadsAvailable, 
                                                        FDWritesAvailable, 
                                                        TaskReadyAges, 
                                                        RoundRobinToken, tid_, 
                                                        task, HasWork, I_, K, 
                                                        L, kq_out, 
                                                        current_time, lqbuf, 
                                                        wr, tid, I, fildes_, 
                                                        Steps_, fildes, Steps, 
                                                        PolledRead >>

LQ_Flush_To_GQB2(self) == /\ pc[self] = "LQ_Flush_To_GQB2"
                          /\ J' = [J EXCEPT ![self] = 1]
                          /\ pc' = [pc EXCEPT ![self] = "LQ_Flush_To_GQBLoop2"]
                          /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                          GQPPPointer, GQLock, LQA, LQAClock, 
                                          ClkCycles, LQASizes, LQB, LQBSizes, 
                                          LQLocks, TaskIdCurrent, 
                                          TasksFinished, RTStarted, RTStopped, 
                                          Futures, FuturePush, FuturesBlocked, 
                                          FutureWorkers, FDReadsAvailable, 
                                          FDWritesAvailable, KQueues, 
                                          TaskReadyAges, RoundRobinToken, tid_, 
                                          task, HasWork, I_, K, L, kq_out, 
                                          current_time, lqbuf, wr, tid, I, 
                                          fildes_, Steps_, fildes, Steps, 
                                          PolledRead >>

LQ_Flush_To_GQBLoop2(self) == /\ pc[self] = "LQ_Flush_To_GQBLoop2"
                              /\ IF J[self] <= LQSize \div 2
                                    THEN /\ IF LQB[self][J[self]].state = TSBIO
                                               THEN /\ KQueues' = [KQueues EXCEPT ![self].waiting = SelectSeq (KQueues[self].waiting, LAMBDA w: w.fd # LQB[self][J[self]].blocked_io_info.fd \/ w.kind # LQB[self][J[self]].blocked_io_info.ty)]
                                               ELSE /\ TRUE
                                                    /\ UNCHANGED KQueues
                                         /\ pc' = [pc EXCEPT ![self] = "LQ_Flush_To_GQBLoop2AfterCheckContinuation"]
                                         /\ UNCHANGED LQBSizes
                                    ELSE /\ LQBSizes' = [LQBSizes EXCEPT ![self] = LQSize \div 2]
                                         /\ pc' = [pc EXCEPT ![self] = "Flush_To_LQB_Continuation"]
                                         /\ UNCHANGED KQueues
                              /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                              GQBSize, GQPPPointer, GQLock, 
                                              LQA, LQAClock, ClkCycles, 
                                              LQASizes, LQB, LQLocks, 
                                              TaskIdCurrent, TasksFinished, 
                                              RTStarted, RTStopped, Futures, 
                                              FuturePush, FuturesBlocked, 
                                              FutureWorkers, FDReadsAvailable, 
                                              FDWritesAvailable, TaskReadyAges, 
                                              RoundRobinToken, tid_, task, 
                                              HasWork, I_, J, K, L, kq_out, 
                                              current_time, lqbuf, wr, tid, I, 
                                              fildes_, Steps_, fildes, Steps, 
                                              PolledRead >>

LQ_Flush_To_GQBLoop2AfterCheckContinuation(self) == /\ pc[self] = "LQ_Flush_To_GQBLoop2AfterCheckContinuation"
                                                    /\ LQB' = [LQB EXCEPT ![self][J[self]] = LQB[self][J[self] + LQSize \div 2]]
                                                    /\ J' = [J EXCEPT ![self] = J[self] + 1]
                                                    /\ pc' = [pc EXCEPT ![self] = "LQ_Flush_To_GQBLoop2"]
                                                    /\ UNCHANGED << GQA, 
                                                                    GQAFirst, 
                                                                    GQALast, 
                                                                    GQB, 
                                                                    GQBSize, 
                                                                    GQPPPointer, 
                                                                    GQLock, 
                                                                    LQA, 
                                                                    LQAClock, 
                                                                    ClkCycles, 
                                                                    LQASizes, 
                                                                    LQBSizes, 
                                                                    LQLocks, 
                                                                    TaskIdCurrent, 
                                                                    TasksFinished, 
                                                                    RTStarted, 
                                                                    RTStopped, 
                                                                    Futures, 
                                                                    FuturePush, 
                                                                    FuturesBlocked, 
                                                                    FutureWorkers, 
                                                                    FDReadsAvailable, 
                                                                    FDWritesAvailable, 
                                                                    KQueues, 
                                                                    TaskReadyAges, 
                                                                    RoundRobinToken, 
                                                                    tid_, task, 
                                                                    HasWork, 
                                                                    I_, K, L, 
                                                                    kq_out, 
                                                                    current_time, 
                                                                    lqbuf, wr, 
                                                                    tid, I, 
                                                                    fildes_, 
                                                                    Steps_, 
                                                                    fildes, 
                                                                    Steps, 
                                                                    PolledRead >>

LQ_Flush_Step(self) == /\ pc[self] = "LQ_Flush_Step"
                       /\ I_' = [I_ EXCEPT ![self] = I_[self] + 1]
                       /\ pc' = [pc EXCEPT ![self] = "LQ_Flush_Loop"]
                       /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                       GQPPPointer, GQLock, LQA, LQAClock, 
                                       ClkCycles, LQASizes, LQB, LQBSizes, 
                                       LQLocks, TaskIdCurrent, TasksFinished, 
                                       RTStarted, RTStopped, Futures, 
                                       FuturePush, FuturesBlocked, 
                                       FutureWorkers, FDReadsAvailable, 
                                       FDWritesAvailable, KQueues, 
                                       TaskReadyAges, RoundRobinToken, tid_, 
                                       task, HasWork, J, K, L, kq_out, 
                                       current_time, lqbuf, wr, tid, I, 
                                       fildes_, Steps_, fildes, Steps, 
                                       PolledRead >>

LQ_GQ_CheckPushPull(self) == /\ pc[self] = "LQ_GQ_CheckPushPull"
                             /\ ClkCycles' = [ClkCycles EXCEPT ![self] = ClkCycles[self] + 1]
                             /\ IF ClkCycles'[self] = NumClockCyclesBeforeGQPushPull
                                   THEN /\ pc' = [pc EXCEPT ![self] = "Begin_LQ_GQ_PushPull"]
                                   ELSE /\ pc' = [pc EXCEPT ![self] = "LQ_Poll_KQ"]
                             /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                             GQBSize, GQPPPointer, GQLock, LQA, 
                                             LQAClock, LQASizes, LQB, LQBSizes, 
                                             LQLocks, TaskIdCurrent, 
                                             TasksFinished, RTStarted, 
                                             RTStopped, Futures, FuturePush, 
                                             FuturesBlocked, FutureWorkers, 
                                             FDReadsAvailable, 
                                             FDWritesAvailable, KQueues, 
                                             TaskReadyAges, RoundRobinToken, 
                                             tid_, task, HasWork, I_, J, K, L, 
                                             kq_out, current_time, lqbuf, wr, 
                                             tid, I, fildes_, Steps_, fildes, 
                                             Steps, PolledRead >>

Begin_LQ_GQ_PushPull(self) == /\ pc[self] = "Begin_LQ_GQ_PushPull"
                              /\ ClkCycles' = [ClkCycles EXCEPT ![self] = 0]
                              /\ pc' = [pc EXCEPT ![self] = "AttemptEnqueueFromGlobalLockGQ2"]
                              /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                              GQBSize, GQPPPointer, GQLock, 
                                              LQA, LQAClock, LQASizes, LQB, 
                                              LQBSizes, LQLocks, TaskIdCurrent, 
                                              TasksFinished, RTStarted, 
                                              RTStopped, Futures, FuturePush, 
                                              FuturesBlocked, FutureWorkers, 
                                              FDReadsAvailable, 
                                              FDWritesAvailable, KQueues, 
                                              TaskReadyAges, RoundRobinToken, 
                                              tid_, task, HasWork, I_, J, K, L, 
                                              kq_out, current_time, lqbuf, wr, 
                                              tid, I, fildes_, Steps_, fildes, 
                                              Steps, PolledRead >>

AttemptEnqueueFromGlobalLockGQ2(self) == /\ pc[self] = "AttemptEnqueueFromGlobalLockGQ2"
                                         /\ GQLock = NullLock
                                         /\ GQLock' = self
                                         /\ pc' = [pc EXCEPT ![self] = "GQ_Poll_Check_KQ2"]
                                         /\ UNCHANGED << GQA, GQAFirst, 
                                                         GQALast, GQB, GQBSize, 
                                                         GQPPPointer, LQA, 
                                                         LQAClock, ClkCycles, 
                                                         LQASizes, LQB, 
                                                         LQBSizes, LQLocks, 
                                                         TaskIdCurrent, 
                                                         TasksFinished, 
                                                         RTStarted, RTStopped, 
                                                         Futures, FuturePush, 
                                                         FuturesBlocked, 
                                                         FutureWorkers, 
                                                         FDReadsAvailable, 
                                                         FDWritesAvailable, 
                                                         KQueues, 
                                                         TaskReadyAges, 
                                                         RoundRobinToken, tid_, 
                                                         task, HasWork, I_, J, 
                                                         K, L, kq_out, 
                                                         current_time, lqbuf, 
                                                         wr, tid, I, fildes_, 
                                                         Steps_, fildes, Steps, 
                                                         PolledRead >>

GQ_Poll_Check_KQ2(self) == /\ pc[self] = "GQ_Poll_Check_KQ2"
                           /\ IF KQueues[0] = NullKQ
                                 THEN /\ pc' = [pc EXCEPT ![self] = "GQ_Flush_Ready_Begin2"]
                                 ELSE /\ pc' = [pc EXCEPT ![self] = "GQ_Poll_KQ_Begin2"]
                           /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                           GQBSize, GQPPPointer, GQLock, LQA, 
                                           LQAClock, ClkCycles, LQASizes, LQB, 
                                           LQBSizes, LQLocks, TaskIdCurrent, 
                                           TasksFinished, RTStarted, RTStopped, 
                                           Futures, FuturePush, FuturesBlocked, 
                                           FutureWorkers, FDReadsAvailable, 
                                           FDWritesAvailable, KQueues, 
                                           TaskReadyAges, RoundRobinToken, 
                                           tid_, task, HasWork, I_, J, K, L, 
                                           kq_out, current_time, lqbuf, wr, 
                                           tid, I, fildes_, Steps_, fildes, 
                                           Steps, PolledRead >>

GQ_Poll_KQ_Begin2(self) == /\ pc[self] = "GQ_Poll_KQ_Begin2"
                           /\ kq_out' = [kq_out EXCEPT ![self] = SubSeq(KQueues[0].available, 1, MinNum(KQPollNum, Len(KQueues[0].available)))]
                           /\ KQueues' = [KQueues EXCEPT ![0].available = IF KQPollNum < Len(KQueues[0].available)
                                                                          THEN SubSeq(KQueues[0].available, KQPollNum + 1, Len(KQueues[0].available))
                                                                          ELSE ESeq]
                           /\ pc' = [pc EXCEPT ![self] = "GQ_Update_Ready2"]
                           /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                           GQBSize, GQPPPointer, GQLock, LQA, 
                                           LQAClock, ClkCycles, LQASizes, LQB, 
                                           LQBSizes, LQLocks, TaskIdCurrent, 
                                           TasksFinished, RTStarted, RTStopped, 
                                           Futures, FuturePush, FuturesBlocked, 
                                           FutureWorkers, FDReadsAvailable, 
                                           FDWritesAvailable, TaskReadyAges, 
                                           RoundRobinToken, tid_, task, 
                                           HasWork, I_, J, K, L, current_time, 
                                           lqbuf, wr, tid, I, fildes_, Steps_, 
                                           fildes, Steps, PolledRead >>

GQ_Update_Ready2(self) == /\ pc[self] = "GQ_Update_Ready2"
                          /\ GQB' =    [i \in GQ |->
                                    IF i \in 1..GQBSize /\ \E x \in DOMAIN kq_out[self]: GQB[self][i].t_id = kq_out[self][x].t_id THEN
                                        LET x == CHOOSE x \in DOMAIN kq_out[self]: kq_out[self][x].t_id = LQB[i].t_id
                                        IN
                                            [LQB[i] EXCEPT
                                                !.state = TSReady,
                                                !.blocked_io_info.data = kq_out[self][x].data,
                                                !.blocked_io_info.eof = kq_out[self][x].eof
                                            ]
                                    ELSE GQB[i]]
                          /\ pc' = [pc EXCEPT ![self] = "GQ_Flush_Ready_Begin2"]
                          /\ UNCHANGED << GQA, GQAFirst, GQALast, GQBSize, 
                                          GQPPPointer, GQLock, LQA, LQAClock, 
                                          ClkCycles, LQASizes, LQB, LQBSizes, 
                                          LQLocks, TaskIdCurrent, 
                                          TasksFinished, RTStarted, RTStopped, 
                                          Futures, FuturePush, FuturesBlocked, 
                                          FutureWorkers, FDReadsAvailable, 
                                          FDWritesAvailable, KQueues, 
                                          TaskReadyAges, RoundRobinToken, tid_, 
                                          task, HasWork, I_, J, K, L, kq_out, 
                                          current_time, lqbuf, wr, tid, I, 
                                          fildes_, Steps_, fildes, Steps, 
                                          PolledRead >>

GQ_Flush_Ready_Begin2(self) == /\ pc[self] = "GQ_Flush_Ready_Begin2"
                               /\ I_' = [I_ EXCEPT ![self] = 1]
                               /\ K' = [K EXCEPT ![self] = 0]
                               /\ pc' = [pc EXCEPT ![self] = "GQ_Flush_Ready2"]
                               /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                               GQBSize, GQPPPointer, GQLock, 
                                               LQA, LQAClock, ClkCycles, 
                                               LQASizes, LQB, LQBSizes, 
                                               LQLocks, TaskIdCurrent, 
                                               TasksFinished, RTStarted, 
                                               RTStopped, Futures, FuturePush, 
                                               FuturesBlocked, FutureWorkers, 
                                               FDReadsAvailable, 
                                               FDWritesAvailable, KQueues, 
                                               TaskReadyAges, RoundRobinToken, 
                                               tid_, task, HasWork, J, L, 
                                               kq_out, current_time, lqbuf, wr, 
                                               tid, I, fildes_, Steps_, fildes, 
                                               Steps, PolledRead >>

GQ_Flush_Ready2(self) == /\ pc[self] = "GQ_Flush_Ready2"
                         /\ IF I_[self] <= GQBSize
                               THEN /\ pc' = [pc EXCEPT ![self] = "GQ_Flush_Check_Timer2"]
                               ELSE /\ pc' = [pc EXCEPT ![self] = "GQ_Flush_Ready_Done2"]
                         /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                         GQPPPointer, GQLock, LQA, LQAClock, 
                                         ClkCycles, LQASizes, LQB, LQBSizes, 
                                         LQLocks, TaskIdCurrent, TasksFinished, 
                                         RTStarted, RTStopped, Futures, 
                                         FuturePush, FuturesBlocked, 
                                         FutureWorkers, FDReadsAvailable, 
                                         FDWritesAvailable, KQueues, 
                                         TaskReadyAges, RoundRobinToken, tid_, 
                                         task, HasWork, I_, J, K, L, kq_out, 
                                         current_time, lqbuf, wr, tid, I, 
                                         fildes_, Steps_, fildes, Steps, 
                                         PolledRead >>

GQ_Flush_Check_Timer2(self) == /\ pc[self] = "GQ_Flush_Check_Timer2"
                               /\ IF GQB[I_[self]].state = TSBTimer
                                     THEN /\ \/ /\ GQB' = [GQB EXCEPT ![I_[self]].state = TSReady]
                                             \/ /\ TRUE
                                                /\ GQB' = GQB
                                     ELSE /\ TRUE
                                          /\ GQB' = GQB
                               /\ pc' = [pc EXCEPT ![self] = "GQ_Flush_Ready_Check_Ready2"]
                               /\ UNCHANGED << GQA, GQAFirst, GQALast, GQBSize, 
                                               GQPPPointer, GQLock, LQA, 
                                               LQAClock, ClkCycles, LQASizes, 
                                               LQB, LQBSizes, LQLocks, 
                                               TaskIdCurrent, TasksFinished, 
                                               RTStarted, RTStopped, Futures, 
                                               FuturePush, FuturesBlocked, 
                                               FutureWorkers, FDReadsAvailable, 
                                               FDWritesAvailable, KQueues, 
                                               TaskReadyAges, RoundRobinToken, 
                                               tid_, task, HasWork, I_, J, K, 
                                               L, kq_out, current_time, lqbuf, 
                                               wr, tid, I, fildes_, Steps_, 
                                               fildes, Steps, PolledRead >>

GQ_Flush_Ready_Check_Ready2(self) == /\ pc[self] = "GQ_Flush_Ready_Check_Ready2"
                                     /\ IF GQB[I_[self]].state = TSReady
                                           THEN /\ GQALast' = GQALast + 1
                                                /\ GQA' = [GQA EXCEPT ![((GQALast' - 1) % GQSize) + 1] = GQB[I_[self]]]
                                                /\ TaskReadyAges' = [TaskReadyAges EXCEPT ![GQB[I_[self]].t_id] = 0]
                                                /\ UNCHANGED << GQB, K >>
                                           ELSE /\ K' = [K EXCEPT ![self] = K[self] + 1]
                                                /\ GQB' = [GQB EXCEPT ![K'[self]] = GQB[I_[self]]]
                                                /\ UNCHANGED << GQA, GQALast, 
                                                                TaskReadyAges >>
                                     /\ pc' = [pc EXCEPT ![self] = "GQ_Flush_Ready_Step2"]
                                     /\ UNCHANGED << GQAFirst, GQBSize, 
                                                     GQPPPointer, GQLock, LQA, 
                                                     LQAClock, ClkCycles, 
                                                     LQASizes, LQB, LQBSizes, 
                                                     LQLocks, TaskIdCurrent, 
                                                     TasksFinished, RTStarted, 
                                                     RTStopped, Futures, 
                                                     FuturePush, 
                                                     FuturesBlocked, 
                                                     FutureWorkers, 
                                                     FDReadsAvailable, 
                                                     FDWritesAvailable, 
                                                     KQueues, RoundRobinToken, 
                                                     tid_, task, HasWork, I_, 
                                                     J, L, kq_out, 
                                                     current_time, lqbuf, wr, 
                                                     tid, I, fildes_, Steps_, 
                                                     fildes, Steps, PolledRead >>

GQ_Flush_Ready_Step2(self) == /\ pc[self] = "GQ_Flush_Ready_Step2"
                              /\ I_' = [I_ EXCEPT ![self] = I_[self] + 1]
                              /\ pc' = [pc EXCEPT ![self] = "GQ_Flush_Ready2"]
                              /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                              GQBSize, GQPPPointer, GQLock, 
                                              LQA, LQAClock, ClkCycles, 
                                              LQASizes, LQB, LQBSizes, LQLocks, 
                                              TaskIdCurrent, TasksFinished, 
                                              RTStarted, RTStopped, Futures, 
                                              FuturePush, FuturesBlocked, 
                                              FutureWorkers, FDReadsAvailable, 
                                              FDWritesAvailable, KQueues, 
                                              TaskReadyAges, RoundRobinToken, 
                                              tid_, task, HasWork, J, K, L, 
                                              kq_out, current_time, lqbuf, wr, 
                                              tid, I, fildes_, Steps_, fildes, 
                                              Steps, PolledRead >>

GQ_Flush_Ready_Done2(self) == /\ pc[self] = "GQ_Flush_Ready_Done2"
                              /\ GQBSize' = K[self]
                              /\ I_' = [I_ EXCEPT ![self] = GQAFirst + 1]
                              /\ K' = [K EXCEPT ![self] = 0]
                              /\ pc' = [pc EXCEPT ![self] = "AttemptEnqueueFromGlobalWhile2"]
                              /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                              GQPPPointer, GQLock, LQA, 
                                              LQAClock, ClkCycles, LQASizes, 
                                              LQB, LQBSizes, LQLocks, 
                                              TaskIdCurrent, TasksFinished, 
                                              RTStarted, RTStopped, Futures, 
                                              FuturePush, FuturesBlocked, 
                                              FutureWorkers, FDReadsAvailable, 
                                              FDWritesAvailable, KQueues, 
                                              TaskReadyAges, RoundRobinToken, 
                                              tid_, task, HasWork, J, L, 
                                              kq_out, current_time, lqbuf, wr, 
                                              tid, I, fildes_, Steps_, fildes, 
                                              Steps, PolledRead >>

AttemptEnqueueFromGlobalWhile2(self) == /\ pc[self] = "AttemptEnqueueFromGlobalWhile2"
                                        /\ IF I_[self] <= GQALast /\ K[self] < (LQSize \div 2)
                                              THEN /\ K' = [K EXCEPT ![self] = K[self] + 1]
                                                   /\ LQA' = [LQA EXCEPT ![self][K'[self]] = GQA[I_[self]]]
                                                   /\ I_' = [I_ EXCEPT ![self] = I_[self] + 1]
                                                   /\ pc' = [pc EXCEPT ![self] = "AttemptEnqueueFromGlobalWhile2"]
                                              ELSE /\ pc' = [pc EXCEPT ![self] = "UpdateGQAPointers2"]
                                                   /\ UNCHANGED << LQA, I_, K >>
                                        /\ UNCHANGED << GQA, GQAFirst, GQALast, 
                                                        GQB, GQBSize, 
                                                        GQPPPointer, GQLock, 
                                                        LQAClock, ClkCycles, 
                                                        LQASizes, LQB, 
                                                        LQBSizes, LQLocks, 
                                                        TaskIdCurrent, 
                                                        TasksFinished, 
                                                        RTStarted, RTStopped, 
                                                        Futures, FuturePush, 
                                                        FuturesBlocked, 
                                                        FutureWorkers, 
                                                        FDReadsAvailable, 
                                                        FDWritesAvailable, 
                                                        KQueues, TaskReadyAges, 
                                                        RoundRobinToken, tid_, 
                                                        task, HasWork, J, L, 
                                                        kq_out, current_time, 
                                                        lqbuf, wr, tid, I, 
                                                        fildes_, Steps_, 
                                                        fildes, Steps, 
                                                        PolledRead >>

UpdateGQAPointers2(self) == /\ pc[self] = "UpdateGQAPointers2"
                            /\ GQAFirst' = I_[self] - 1
                            /\ pc' = [pc EXCEPT ![self] = "UpdateGQAPointersCheck2"]
                            /\ UNCHANGED << GQA, GQALast, GQB, GQBSize, 
                                            GQPPPointer, GQLock, LQA, LQAClock, 
                                            ClkCycles, LQASizes, LQB, LQBSizes, 
                                            LQLocks, TaskIdCurrent, 
                                            TasksFinished, RTStarted, 
                                            RTStopped, Futures, FuturePush, 
                                            FuturesBlocked, FutureWorkers, 
                                            FDReadsAvailable, 
                                            FDWritesAvailable, KQueues, 
                                            TaskReadyAges, RoundRobinToken, 
                                            tid_, task, HasWork, I_, J, K, L, 
                                            kq_out, current_time, lqbuf, wr, 
                                            tid, I, fildes_, Steps_, fildes, 
                                            Steps, PolledRead >>

UpdateGQAPointersCheck2(self) == /\ pc[self] = "UpdateGQAPointersCheck2"
                                 /\ IF GQAFirst > GQSize
                                       THEN /\ GQAFirst' = GQAFirst - GQSize
                                            /\ GQALast' = GQALast - GQSize
                                            /\ GQPPPointer' = GQPPPointer - GQSize
                                       ELSE /\ TRUE
                                            /\ UNCHANGED << GQAFirst, GQALast, 
                                                            GQPPPointer >>
                                 /\ pc' = [pc EXCEPT ![self] = "PushPullBegin"]
                                 /\ UNCHANGED << GQA, GQB, GQBSize, GQLock, 
                                                 LQA, LQAClock, ClkCycles, 
                                                 LQASizes, LQB, LQBSizes, 
                                                 LQLocks, TaskIdCurrent, 
                                                 TasksFinished, RTStarted, 
                                                 RTStopped, Futures, 
                                                 FuturePush, FuturesBlocked, 
                                                 FutureWorkers, 
                                                 FDReadsAvailable, 
                                                 FDWritesAvailable, KQueues, 
                                                 TaskReadyAges, 
                                                 RoundRobinToken, tid_, task, 
                                                 HasWork, I_, J, K, L, kq_out, 
                                                 current_time, lqbuf, wr, tid, 
                                                 I, fildes_, Steps_, fildes, 
                                                 Steps, PolledRead >>

PushPullBegin(self) == /\ pc[self] = "PushPullBegin"
                       /\ GQPPPointer' = (IF GQPPPointer <= GQAFirst THEN GQAFirst + 1 ELSE GQPPPointer + 1)
                       /\ I_' = [I_ EXCEPT ![self] = GQPPPointer']
                       /\ K' = [K EXCEPT ![self] = 1]
                       /\ pc' = [pc EXCEPT ![self] = "PerformFirstPushPull"]
                       /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                       GQLock, LQA, LQAClock, ClkCycles, 
                                       LQASizes, LQB, LQBSizes, LQLocks, 
                                       TaskIdCurrent, TasksFinished, RTStarted, 
                                       RTStopped, Futures, FuturePush, 
                                       FuturesBlocked, FutureWorkers, 
                                       FDReadsAvailable, FDWritesAvailable, 
                                       KQueues, TaskReadyAges, RoundRobinToken, 
                                       tid_, task, HasWork, J, L, kq_out, 
                                       current_time, lqbuf, wr, tid, I, 
                                       fildes_, Steps_, fildes, Steps, 
                                       PolledRead >>

PerformFirstPushPull(self) == /\ pc[self] = "PerformFirstPushPull"
                              /\ IF GQPPPointer <= GQALast /\ K[self] <= LQASizes[self]
                                    THEN /\ task' = [task EXCEPT ![self] = LQA[K[self]]]
                                         /\ LQA' = [LQA EXCEPT ![K[self]] = GQA[((GQPPPointer - 1) % GQ) + 1]]
                                         /\ GQA' = [GQA EXCEPT ![((GQPPPointer - 1) % GQ) + 1] = task'[self]]
                                         /\ GQPPPointer' = (IF GQPPPointer < GQALast THEN GQPPPointer + 1 ELSE GQAFirst + 1)
                                         /\ K' = [K EXCEPT ![self] = K[self] + 1]
                                         /\ pc' = [pc EXCEPT ![self] = "PushPull"]
                                    ELSE /\ pc' = [pc EXCEPT ![self] = "AttemptEnqueueFromGlobalFinish2"]
                                         /\ UNCHANGED << GQA, GQPPPointer, LQA, 
                                                         task, K >>
                              /\ UNCHANGED << GQAFirst, GQALast, GQB, GQBSize, 
                                              GQLock, LQAClock, ClkCycles, 
                                              LQASizes, LQB, LQBSizes, LQLocks, 
                                              TaskIdCurrent, TasksFinished, 
                                              RTStarted, RTStopped, Futures, 
                                              FuturePush, FuturesBlocked, 
                                              FutureWorkers, FDReadsAvailable, 
                                              FDWritesAvailable, KQueues, 
                                              TaskReadyAges, RoundRobinToken, 
                                              tid_, HasWork, I_, J, L, kq_out, 
                                              current_time, lqbuf, wr, tid, I, 
                                              fildes_, Steps_, fildes, Steps, 
                                              PolledRead >>

PushPull(self) == /\ pc[self] = "PushPull"
                  /\ IF GQPPPointer # I_[self] /\ K[self] <= LQASizes[self]
                        THEN /\ pc' = [pc EXCEPT ![self] = "PerformPushPull"]
                        ELSE /\ pc' = [pc EXCEPT ![self] = "AttemptEnqueueFromGlobalFinish2"]
                  /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                  GQPPPointer, GQLock, LQA, LQAClock, 
                                  ClkCycles, LQASizes, LQB, LQBSizes, LQLocks, 
                                  TaskIdCurrent, TasksFinished, RTStarted, 
                                  RTStopped, Futures, FuturePush, 
                                  FuturesBlocked, FutureWorkers, 
                                  FDReadsAvailable, FDWritesAvailable, KQueues, 
                                  TaskReadyAges, RoundRobinToken, tid_, task, 
                                  HasWork, I_, J, K, L, kq_out, current_time, 
                                  lqbuf, wr, tid, I, fildes_, Steps_, fildes, 
                                  Steps, PolledRead >>

PerformPushPull(self) == /\ pc[self] = "PerformPushPull"
                         /\ task' = [task EXCEPT ![self] = LQA[K[self]]]
                         /\ LQA' = [LQA EXCEPT ![K[self]] = GQA[((GQPPPointer - 1) % GQ) + 1]]
                         /\ GQA' = [GQA EXCEPT ![((GQPPPointer - 1) % GQ) + 1] = task'[self]]
                         /\ pc' = [pc EXCEPT ![self] = "PushPullStep"]
                         /\ UNCHANGED << GQAFirst, GQALast, GQB, GQBSize, 
                                         GQPPPointer, GQLock, LQAClock, 
                                         ClkCycles, LQASizes, LQB, LQBSizes, 
                                         LQLocks, TaskIdCurrent, TasksFinished, 
                                         RTStarted, RTStopped, Futures, 
                                         FuturePush, FuturesBlocked, 
                                         FutureWorkers, FDReadsAvailable, 
                                         FDWritesAvailable, KQueues, 
                                         TaskReadyAges, RoundRobinToken, tid_, 
                                         HasWork, I_, J, K, L, kq_out, 
                                         current_time, lqbuf, wr, tid, I, 
                                         fildes_, Steps_, fildes, Steps, 
                                         PolledRead >>

PushPullStep(self) == /\ pc[self] = "PushPullStep"
                      /\ GQPPPointer' = (IF GQPPPointer < GQALast THEN GQPPPointer + 1 ELSE GQAFirst + 1)
                      /\ K' = [K EXCEPT ![self] = K[self] + 1]
                      /\ pc' = [pc EXCEPT ![self] = "PushPull"]
                      /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                      GQLock, LQA, LQAClock, ClkCycles, 
                                      LQASizes, LQB, LQBSizes, LQLocks, 
                                      TaskIdCurrent, TasksFinished, RTStarted, 
                                      RTStopped, Futures, FuturePush, 
                                      FuturesBlocked, FutureWorkers, 
                                      FDReadsAvailable, FDWritesAvailable, 
                                      KQueues, TaskReadyAges, RoundRobinToken, 
                                      tid_, task, HasWork, I_, J, L, kq_out, 
                                      current_time, lqbuf, wr, tid, I, fildes_, 
                                      Steps_, fildes, Steps, PolledRead >>

AttemptEnqueueFromGlobalFinish2(self) == /\ pc[self] = "AttemptEnqueueFromGlobalFinish2"
                                         /\ GQLock' = NullLock
                                         /\ pc' = [pc EXCEPT ![self] = "LQ_Poll_KQ"]
                                         /\ UNCHANGED << GQA, GQAFirst, 
                                                         GQALast, GQB, GQBSize, 
                                                         GQPPPointer, LQA, 
                                                         LQAClock, ClkCycles, 
                                                         LQASizes, LQB, 
                                                         LQBSizes, LQLocks, 
                                                         TaskIdCurrent, 
                                                         TasksFinished, 
                                                         RTStarted, RTStopped, 
                                                         Futures, FuturePush, 
                                                         FuturesBlocked, 
                                                         FutureWorkers, 
                                                         FDReadsAvailable, 
                                                         FDWritesAvailable, 
                                                         KQueues, 
                                                         TaskReadyAges, 
                                                         RoundRobinToken, tid_, 
                                                         task, HasWork, I_, J, 
                                                         K, L, kq_out, 
                                                         current_time, lqbuf, 
                                                         wr, tid, I, fildes_, 
                                                         Steps_, fildes, Steps, 
                                                         PolledRead >>

LQ_Poll_KQ(self) == /\ pc[self] = "LQ_Poll_KQ"
                    /\ IF KQueues[self] # NullKQ
                          THEN /\ pc' = [pc EXCEPT ![self] = "LQ_Poll_KQ_Begin"]
                          ELSE /\ pc' = [pc EXCEPT ![self] = "Flush_Ready_Begin"]
                    /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                    GQPPPointer, GQLock, LQA, LQAClock, 
                                    ClkCycles, LQASizes, LQB, LQBSizes, 
                                    LQLocks, TaskIdCurrent, TasksFinished, 
                                    RTStarted, RTStopped, Futures, FuturePush, 
                                    FuturesBlocked, FutureWorkers, 
                                    FDReadsAvailable, FDWritesAvailable, 
                                    KQueues, TaskReadyAges, RoundRobinToken, 
                                    tid_, task, HasWork, I_, J, K, L, kq_out, 
                                    current_time, lqbuf, wr, tid, I, fildes_, 
                                    Steps_, fildes, Steps, PolledRead >>

LQ_Poll_KQ_Begin(self) == /\ pc[self] = "LQ_Poll_KQ_Begin"
                          /\ kq_out' = [kq_out EXCEPT ![self] = SubSeq(KQueues[self].available, 1, MinNum(KQPollNum, Len(KQueues[self].available)))]
                          /\ KQueues' = [KQueues EXCEPT ![self].available = IF KQPollNum < Len(KQueues[self].available)
                                                                            THEN SubSeq(KQueues[self].available, KQPollNum + 1, Len(KQueues[self].available))
                                                                            ELSE ESeq]
                          /\ pc' = [pc EXCEPT ![self] = "Update_Ready"]
                          /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                          GQPPPointer, GQLock, LQA, LQAClock, 
                                          ClkCycles, LQASizes, LQB, LQBSizes, 
                                          LQLocks, TaskIdCurrent, 
                                          TasksFinished, RTStarted, RTStopped, 
                                          Futures, FuturePush, FuturesBlocked, 
                                          FutureWorkers, FDReadsAvailable, 
                                          FDWritesAvailable, TaskReadyAges, 
                                          RoundRobinToken, tid_, task, HasWork, 
                                          I_, J, K, L, current_time, lqbuf, wr, 
                                          tid, I, fildes_, Steps_, fildes, 
                                          Steps, PolledRead >>

Update_Ready(self) == /\ pc[self] = "Update_Ready"
                      /\ LQB' = [LQB EXCEPT ![self] =          [i \in LQ |->
                                                      IF i \in 1..LQBSizes[self] /\ \E x \in DOMAIN kq_out[self]: LQB[self][i].t_id = kq_out[self][x].t_id THEN
                                                          LET x == CHOOSE x \in DOMAIN kq_out[self]: kq_out[self][x].t_id = LQB[self][i].t_id
                                                          IN
                                                              [LQB[self][i] EXCEPT
                                                                  !.state = TSReady,
                                                                  !.blocked_io_info.data = kq_out[self][x].data,
                                                                  !.blocked_io_info.eof = kq_out[self][x].eof
                                                              ]
                                                      ELSE LQB[self][i]]]
                      /\ pc' = [pc EXCEPT ![self] = "Flush_Ready_Begin"]
                      /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                      GQPPPointer, GQLock, LQA, LQAClock, 
                                      ClkCycles, LQASizes, LQBSizes, LQLocks, 
                                      TaskIdCurrent, TasksFinished, RTStarted, 
                                      RTStopped, Futures, FuturePush, 
                                      FuturesBlocked, FutureWorkers, 
                                      FDReadsAvailable, FDWritesAvailable, 
                                      KQueues, TaskReadyAges, RoundRobinToken, 
                                      tid_, task, HasWork, I_, J, K, L, kq_out, 
                                      current_time, lqbuf, wr, tid, I, fildes_, 
                                      Steps_, fildes, Steps, PolledRead >>

Flush_Ready_Begin(self) == /\ pc[self] = "Flush_Ready_Begin"
                           /\ I_' = [I_ EXCEPT ![self] = 1]
                           /\ K' = [K EXCEPT ![self] = 0]
                           /\ pc' = [pc EXCEPT ![self] = "Flush_Ready"]
                           /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                           GQBSize, GQPPPointer, GQLock, LQA, 
                                           LQAClock, ClkCycles, LQASizes, LQB, 
                                           LQBSizes, LQLocks, TaskIdCurrent, 
                                           TasksFinished, RTStarted, RTStopped, 
                                           Futures, FuturePush, FuturesBlocked, 
                                           FutureWorkers, FDReadsAvailable, 
                                           FDWritesAvailable, KQueues, 
                                           TaskReadyAges, RoundRobinToken, 
                                           tid_, task, HasWork, J, L, kq_out, 
                                           current_time, lqbuf, wr, tid, I, 
                                           fildes_, Steps_, fildes, Steps, 
                                           PolledRead >>

Flush_Ready(self) == /\ pc[self] = "Flush_Ready"
                     /\ IF I_[self] <= LQBSizes[self]
                           THEN /\ pc' = [pc EXCEPT ![self] = "Flush_Check_Timer"]
                           ELSE /\ pc' = [pc EXCEPT ![self] = "Flush_Ready_Done"]
                     /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                     GQPPPointer, GQLock, LQA, LQAClock, 
                                     ClkCycles, LQASizes, LQB, LQBSizes, 
                                     LQLocks, TaskIdCurrent, TasksFinished, 
                                     RTStarted, RTStopped, Futures, FuturePush, 
                                     FuturesBlocked, FutureWorkers, 
                                     FDReadsAvailable, FDWritesAvailable, 
                                     KQueues, TaskReadyAges, RoundRobinToken, 
                                     tid_, task, HasWork, I_, J, K, L, kq_out, 
                                     current_time, lqbuf, wr, tid, I, fildes_, 
                                     Steps_, fildes, Steps, PolledRead >>

Flush_Check_Timer(self) == /\ pc[self] = "Flush_Check_Timer"
                           /\ IF LQB[self][I_[self]].state = TSBTimer
                                 THEN /\ \/ /\ LQB' = [LQB EXCEPT ![self][I_[self]].state = TSReady]
                                         \/ /\ TRUE
                                            /\ LQB' = LQB
                                 ELSE /\ TRUE
                                      /\ LQB' = LQB
                           /\ pc' = [pc EXCEPT ![self] = "Flush_Ready_Check_Ready"]
                           /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                           GQBSize, GQPPPointer, GQLock, LQA, 
                                           LQAClock, ClkCycles, LQASizes, 
                                           LQBSizes, LQLocks, TaskIdCurrent, 
                                           TasksFinished, RTStarted, RTStopped, 
                                           Futures, FuturePush, FuturesBlocked, 
                                           FutureWorkers, FDReadsAvailable, 
                                           FDWritesAvailable, KQueues, 
                                           TaskReadyAges, RoundRobinToken, 
                                           tid_, task, HasWork, I_, J, K, L, 
                                           kq_out, current_time, lqbuf, wr, 
                                           tid, I, fildes_, Steps_, fildes, 
                                           Steps, PolledRead >>

Flush_Ready_Check_Ready(self) == /\ pc[self] = "Flush_Ready_Check_Ready"
                                 /\ IF LQB[self][I_[self]].state = TSReady
                                       THEN /\ pc' = [pc EXCEPT ![self] = "CheckLQSize_"]
                                            /\ UNCHANGED << LQB, K >>
                                       ELSE /\ K' = [K EXCEPT ![self] = K[self] + 1]
                                            /\ LQB' = [LQB EXCEPT ![self][K'[self]] = LQB[self][I_[self]]]
                                            /\ IF I_[self] # K'[self]
                                                  THEN /\ pc' = [pc EXCEPT ![self] = "Flush_Ready_Check_Ready_Move_Old"]
                                                  ELSE /\ pc' = [pc EXCEPT ![self] = "Flush_Ready_Step"]
                                 /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                                 GQBSize, GQPPPointer, GQLock, 
                                                 LQA, LQAClock, ClkCycles, 
                                                 LQASizes, LQBSizes, LQLocks, 
                                                 TaskIdCurrent, TasksFinished, 
                                                 RTStarted, RTStopped, Futures, 
                                                 FuturePush, FuturesBlocked, 
                                                 FutureWorkers, 
                                                 FDReadsAvailable, 
                                                 FDWritesAvailable, KQueues, 
                                                 TaskReadyAges, 
                                                 RoundRobinToken, tid_, task, 
                                                 HasWork, I_, J, L, kq_out, 
                                                 current_time, lqbuf, wr, tid, 
                                                 I, fildes_, Steps_, fildes, 
                                                 Steps, PolledRead >>

CheckLQSize_(self) == /\ pc[self] = "CheckLQSize_"
                      /\ IF LQASizes[self] = LQSize
                            THEN /\ pc' = [pc EXCEPT ![self] = "LockGQ_"]
                            ELSE /\ pc' = [pc EXCEPT ![self] = "PushLQ_"]
                      /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                      GQPPPointer, GQLock, LQA, LQAClock, 
                                      ClkCycles, LQASizes, LQB, LQBSizes, 
                                      LQLocks, TaskIdCurrent, TasksFinished, 
                                      RTStarted, RTStopped, Futures, 
                                      FuturePush, FuturesBlocked, 
                                      FutureWorkers, FDReadsAvailable, 
                                      FDWritesAvailable, KQueues, 
                                      TaskReadyAges, RoundRobinToken, tid_, 
                                      task, HasWork, I_, J, K, L, kq_out, 
                                      current_time, lqbuf, wr, tid, I, fildes_, 
                                      Steps_, fildes, Steps, PolledRead >>

LockGQ_(self) == /\ pc[self] = "LockGQ_"
                 /\ GQLock = NullLock
                 /\ GQLock' = self
                 /\ L' = [L EXCEPT ![self] = LQSize \div 2 + 1]
                 /\ pc' = [pc EXCEPT ![self] = "PushGQLoop_"]
                 /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                 GQPPPointer, LQA, LQAClock, ClkCycles, 
                                 LQASizes, LQB, LQBSizes, LQLocks, 
                                 TaskIdCurrent, TasksFinished, RTStarted, 
                                 RTStopped, Futures, FuturePush, 
                                 FuturesBlocked, FutureWorkers, 
                                 FDReadsAvailable, FDWritesAvailable, KQueues, 
                                 TaskReadyAges, RoundRobinToken, tid_, task, 
                                 HasWork, I_, J, K, kq_out, current_time, 
                                 lqbuf, wr, tid, I, fildes_, Steps_, fildes, 
                                 Steps, PolledRead >>

PushGQLoop_(self) == /\ pc[self] = "PushGQLoop_"
                     /\ IF L[self] < LQSize
                           THEN /\ pc' = [pc EXCEPT ![self] = "PushGQStatusCheck_"]
                           ELSE /\ pc' = [pc EXCEPT ![self] = "UnlockGQ_"]
                     /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                     GQPPPointer, GQLock, LQA, LQAClock, 
                                     ClkCycles, LQASizes, LQB, LQBSizes, 
                                     LQLocks, TaskIdCurrent, TasksFinished, 
                                     RTStarted, RTStopped, Futures, FuturePush, 
                                     FuturesBlocked, FutureWorkers, 
                                     FDReadsAvailable, FDWritesAvailable, 
                                     KQueues, TaskReadyAges, RoundRobinToken, 
                                     tid_, task, HasWork, I_, J, K, L, kq_out, 
                                     current_time, lqbuf, wr, tid, I, fildes_, 
                                     Steps_, fildes, Steps, PolledRead >>

PushGQStatusCheck_(self) == /\ pc[self] = "PushGQStatusCheck_"
                            /\ IF LQA[self][L[self]] # NullTask
                                  THEN /\ pc' = [pc EXCEPT ![self] = "PushTaskNotNull_"]
                                  ELSE /\ pc' = [pc EXCEPT ![self] = "GQPushWhileStep_"]
                            /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                            GQBSize, GQPPPointer, GQLock, LQA, 
                                            LQAClock, ClkCycles, LQASizes, LQB, 
                                            LQBSizes, LQLocks, TaskIdCurrent, 
                                            TasksFinished, RTStarted, 
                                            RTStopped, Futures, FuturePush, 
                                            FuturesBlocked, FutureWorkers, 
                                            FDReadsAvailable, 
                                            FDWritesAvailable, KQueues, 
                                            TaskReadyAges, RoundRobinToken, 
                                            tid_, task, HasWork, I_, J, K, L, 
                                            kq_out, current_time, lqbuf, wr, 
                                            tid, I, fildes_, Steps_, fildes, 
                                            Steps, PolledRead >>

PushTaskNotNull_(self) == /\ pc[self] = "PushTaskNotNull_"
                          /\ IF LQA[self][L[self]].state = TSReady
                                THEN /\ GQALast' = GQALast + 1
                                     /\ GQA' = [GQA EXCEPT ![((GQALast' - 1) % GQSize) + 1] = LQA[self][L[self]]]
                                     /\ LQA' = [LQA EXCEPT ![self][L[self]] = NullTask]
                                     /\ pc' = [pc EXCEPT ![self] = "GQPushWhileStep_"]
                                     /\ UNCHANGED << GQB, GQBSize, KQueues >>
                                ELSE /\ IF LQA[self][L[self]].state \in {TSBTimer, TSBIO}
                                           THEN /\ GQBSize' = GQBSize + 1
                                                /\ GQB' = [GQB EXCEPT ![GQBSize'] = LQA[self][L[self]]]
                                                /\ LQA' = [LQA EXCEPT ![self][L[self]] = NullTask]
                                                /\ IF KQueues[0] = NullKQ
                                                      THEN /\ KQueues' = [KQueues EXCEPT ![0] = NewKQ]
                                                      ELSE /\ TRUE
                                                           /\ UNCHANGED KQueues
                                                /\ pc' = [pc EXCEPT ![self] = "PushGQPushToKQ_"]
                                           ELSE /\ pc' = [pc EXCEPT ![self] = "GQPushWhileStep_"]
                                                /\ UNCHANGED << GQB, GQBSize, 
                                                                LQA, KQueues >>
                                     /\ UNCHANGED << GQA, GQALast >>
                          /\ UNCHANGED << GQAFirst, GQPPPointer, GQLock, 
                                          LQAClock, ClkCycles, LQASizes, LQB, 
                                          LQBSizes, LQLocks, TaskIdCurrent, 
                                          TasksFinished, RTStarted, RTStopped, 
                                          Futures, FuturePush, FuturesBlocked, 
                                          FutureWorkers, FDReadsAvailable, 
                                          FDWritesAvailable, TaskReadyAges, 
                                          RoundRobinToken, tid_, task, HasWork, 
                                          I_, J, K, L, kq_out, current_time, 
                                          lqbuf, wr, tid, I, fildes_, Steps_, 
                                          fildes, Steps, PolledRead >>

PushGQPushToKQ_(self) == /\ pc[self] = "PushGQPushToKQ_"
                         /\ IF GQB[GQBSize].state = TSBIO
                               THEN /\ KQueues' = [KQueues EXCEPT ![0].waiting = Append (KQueues[0].waiting, [ fd |-> GQB[GQBSize].blocked_io_info.fd, kind |-> GQB[GQBSize].blocked_io_info.ty, data |-> 0, eof |-> FALSE, t_id |-> GQB[GQBSize].t_id ])]
                               ELSE /\ TRUE
                                    /\ UNCHANGED KQueues
                         /\ pc' = [pc EXCEPT ![self] = "GQPushWhileStep_"]
                         /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                         GQPPPointer, GQLock, LQA, LQAClock, 
                                         ClkCycles, LQASizes, LQB, LQBSizes, 
                                         LQLocks, TaskIdCurrent, TasksFinished, 
                                         RTStarted, RTStopped, Futures, 
                                         FuturePush, FuturesBlocked, 
                                         FutureWorkers, FDReadsAvailable, 
                                         FDWritesAvailable, TaskReadyAges, 
                                         RoundRobinToken, tid_, task, HasWork, 
                                         I_, J, K, L, kq_out, current_time, 
                                         lqbuf, wr, tid, I, fildes_, Steps_, 
                                         fildes, Steps, PolledRead >>

GQPushWhileStep_(self) == /\ pc[self] = "GQPushWhileStep_"
                          /\ L' = [L EXCEPT ![self] = L[self] + 1]
                          /\ pc' = [pc EXCEPT ![self] = "PushGQLoop_"]
                          /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                          GQPPPointer, GQLock, LQA, LQAClock, 
                                          ClkCycles, LQASizes, LQB, LQBSizes, 
                                          LQLocks, TaskIdCurrent, 
                                          TasksFinished, RTStarted, RTStopped, 
                                          Futures, FuturePush, FuturesBlocked, 
                                          FutureWorkers, FDReadsAvailable, 
                                          FDWritesAvailable, KQueues, 
                                          TaskReadyAges, RoundRobinToken, tid_, 
                                          task, HasWork, I_, J, K, kq_out, 
                                          current_time, lqbuf, wr, tid, I, 
                                          fildes_, Steps_, fildes, Steps, 
                                          PolledRead >>

UnlockGQ_(self) == /\ pc[self] = "UnlockGQ_"
                   /\ GQLock' = NullLock
                   /\ LQASizes' = [LQASizes EXCEPT ![self] = LQSize \div 2]
                   /\ pc' = [pc EXCEPT ![self] = "CheckClock_"]
                   /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                   GQPPPointer, LQA, LQAClock, ClkCycles, LQB, 
                                   LQBSizes, LQLocks, TaskIdCurrent, 
                                   TasksFinished, RTStarted, RTStopped, 
                                   Futures, FuturePush, FuturesBlocked, 
                                   FutureWorkers, FDReadsAvailable, 
                                   FDWritesAvailable, KQueues, TaskReadyAges, 
                                   RoundRobinToken, tid_, task, HasWork, I_, J, 
                                   K, L, kq_out, current_time, lqbuf, wr, tid, 
                                   I, fildes_, Steps_, fildes, Steps, 
                                   PolledRead >>

CheckClock_(self) == /\ pc[self] = "CheckClock_"
                     /\ IF LQAClock[self] > LQASizes[self]
                           THEN /\ LQASizes' = [LQASizes EXCEPT ![self] = LQASizes[self] + 1]
                                /\ LQA' = [LQA EXCEPT ![self] = [LQA[self] EXCEPT ![LQASizes'[self]] = LQA[self][LQAClock[self]], ![LQAClock[self]] = NullTask]]
                                /\ LQAClock' = [LQAClock EXCEPT ![self] = LQASizes'[self]]
                           ELSE /\ TRUE
                                /\ UNCHANGED << LQA, LQAClock, LQASizes >>
                     /\ pc' = [pc EXCEPT ![self] = "PushLQ_"]
                     /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                     GQPPPointer, GQLock, ClkCycles, LQB, 
                                     LQBSizes, LQLocks, TaskIdCurrent, 
                                     TasksFinished, RTStarted, RTStopped, 
                                     Futures, FuturePush, FuturesBlocked, 
                                     FutureWorkers, FDReadsAvailable, 
                                     FDWritesAvailable, KQueues, TaskReadyAges, 
                                     RoundRobinToken, tid_, task, HasWork, I_, 
                                     J, K, L, kq_out, current_time, lqbuf, wr, 
                                     tid, I, fildes_, Steps_, fildes, Steps, 
                                     PolledRead >>

PushLQ_(self) == /\ pc[self] = "PushLQ_"
                 /\ LQASizes' = [LQASizes EXCEPT ![self] = LQASizes[self] + 1]
                 /\ LQA' = [LQA EXCEPT ![self][LQASizes'[self]] = LQB[self][I_[self]]]
                 /\ TaskReadyAges' = [TaskReadyAges EXCEPT ![LQA'[self][LQASizes'[self]].t_id] = 0]
                 /\ pc' = [pc EXCEPT ![self] = "Flush_Ready_Step"]
                 /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                 GQPPPointer, GQLock, LQAClock, ClkCycles, LQB, 
                                 LQBSizes, LQLocks, TaskIdCurrent, 
                                 TasksFinished, RTStarted, RTStopped, Futures, 
                                 FuturePush, FuturesBlocked, FutureWorkers, 
                                 FDReadsAvailable, FDWritesAvailable, KQueues, 
                                 RoundRobinToken, tid_, task, HasWork, I_, J, 
                                 K, L, kq_out, current_time, lqbuf, wr, tid, I, 
                                 fildes_, Steps_, fildes, Steps, PolledRead >>

Flush_Ready_Check_Ready_Move_Old(self) == /\ pc[self] = "Flush_Ready_Check_Ready_Move_Old"
                                          /\ LQB' = [LQB EXCEPT ![self][I_[self]] = NullTask]
                                          /\ pc' = [pc EXCEPT ![self] = "Flush_Ready_Step"]
                                          /\ UNCHANGED << GQA, GQAFirst, 
                                                          GQALast, GQB, 
                                                          GQBSize, GQPPPointer, 
                                                          GQLock, LQA, 
                                                          LQAClock, ClkCycles, 
                                                          LQASizes, LQBSizes, 
                                                          LQLocks, 
                                                          TaskIdCurrent, 
                                                          TasksFinished, 
                                                          RTStarted, RTStopped, 
                                                          Futures, FuturePush, 
                                                          FuturesBlocked, 
                                                          FutureWorkers, 
                                                          FDReadsAvailable, 
                                                          FDWritesAvailable, 
                                                          KQueues, 
                                                          TaskReadyAges, 
                                                          RoundRobinToken, 
                                                          tid_, task, HasWork, 
                                                          I_, J, K, L, kq_out, 
                                                          current_time, lqbuf, 
                                                          wr, tid, I, fildes_, 
                                                          Steps_, fildes, 
                                                          Steps, PolledRead >>

Flush_Ready_Step(self) == /\ pc[self] = "Flush_Ready_Step"
                          /\ I_' = [I_ EXCEPT ![self] = I_[self] + 1]
                          /\ pc' = [pc EXCEPT ![self] = "Flush_Ready"]
                          /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                          GQPPPointer, GQLock, LQA, LQAClock, 
                                          ClkCycles, LQASizes, LQB, LQBSizes, 
                                          LQLocks, TaskIdCurrent, 
                                          TasksFinished, RTStarted, RTStopped, 
                                          Futures, FuturePush, FuturesBlocked, 
                                          FutureWorkers, FDReadsAvailable, 
                                          FDWritesAvailable, KQueues, 
                                          TaskReadyAges, RoundRobinToken, tid_, 
                                          task, HasWork, J, K, L, kq_out, 
                                          current_time, lqbuf, wr, tid, I, 
                                          fildes_, Steps_, fildes, Steps, 
                                          PolledRead >>

Flush_Ready_Done(self) == /\ pc[self] = "Flush_Ready_Done"
                          /\ LQBSizes' = [LQBSizes EXCEPT ![self] = K[self]]
                          /\ pc' = [pc EXCEPT ![self] = "LQ_Reset_Clock"]
                          /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                          GQPPPointer, GQLock, LQA, LQAClock, 
                                          ClkCycles, LQASizes, LQB, LQLocks, 
                                          TaskIdCurrent, TasksFinished, 
                                          RTStarted, RTStopped, Futures, 
                                          FuturePush, FuturesBlocked, 
                                          FutureWorkers, FDReadsAvailable, 
                                          FDWritesAvailable, KQueues, 
                                          TaskReadyAges, RoundRobinToken, tid_, 
                                          task, HasWork, I_, J, K, L, kq_out, 
                                          current_time, lqbuf, wr, tid, I, 
                                          fildes_, Steps_, fildes, Steps, 
                                          PolledRead >>

LQ_Reset_Clock(self) == /\ pc[self] = "LQ_Reset_Clock"
                        /\ LQAClock' = [LQAClock EXCEPT ![self] = LQASizes[self] + 1]
                        /\ pc' = [pc EXCEPT ![self] = "LQ_Pull"]
                        /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                        GQPPPointer, GQLock, LQA, ClkCycles, 
                                        LQASizes, LQB, LQBSizes, LQLocks, 
                                        TaskIdCurrent, TasksFinished, 
                                        RTStarted, RTStopped, Futures, 
                                        FuturePush, FuturesBlocked, 
                                        FutureWorkers, FDReadsAvailable, 
                                        FDWritesAvailable, KQueues, 
                                        TaskReadyAges, RoundRobinToken, tid_, 
                                        task, HasWork, I_, J, K, L, kq_out, 
                                        current_time, lqbuf, wr, tid, I, 
                                        fildes_, Steps_, fildes, Steps, 
                                        PolledRead >>

LQ_Pull(self) == /\ pc[self] = "LQ_Pull"
                 /\ IF LQASizes[self] = 0
                       THEN /\ HasWork' = [HasWork EXCEPT ![self] = FALSE]
                            /\ UNCHANGED << LQA, LQAClock, task >>
                       ELSE /\ LQAClock' = [LQAClock EXCEPT ![self] = LQAClock[self] - 1]
                            /\ LQA' = [LQA EXCEPT ![self][LQAClock'[self]].state = TSRunning]
                            /\ task' = [task EXCEPT ![self] = LQA'[self][LQAClock'[self]]]
                            /\ HasWork' = [HasWork EXCEPT ![self] = TRUE]
                 /\ pc' = [pc EXCEPT ![self] = "LQ_Unlock"]
                 /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                 GQPPPointer, GQLock, ClkCycles, LQASizes, LQB, 
                                 LQBSizes, LQLocks, TaskIdCurrent, 
                                 TasksFinished, RTStarted, RTStopped, Futures, 
                                 FuturePush, FuturesBlocked, FutureWorkers, 
                                 FDReadsAvailable, FDWritesAvailable, KQueues, 
                                 TaskReadyAges, RoundRobinToken, tid_, I_, J, 
                                 K, L, kq_out, current_time, lqbuf, wr, tid, I, 
                                 fildes_, Steps_, fildes, Steps, PolledRead >>

LQ_Unlock(self) == /\ pc[self] = "LQ_Unlock"
                   /\ LQLocks' = [LQLocks EXCEPT ![self] = NullLock]
                   /\ pc' = [pc EXCEPT ![self] = "CheckHasWork"]
                   /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                   GQPPPointer, GQLock, LQA, LQAClock, 
                                   ClkCycles, LQASizes, LQB, LQBSizes, 
                                   TaskIdCurrent, TasksFinished, RTStarted, 
                                   RTStopped, Futures, FuturePush, 
                                   FuturesBlocked, FutureWorkers, 
                                   FDReadsAvailable, FDWritesAvailable, 
                                   KQueues, TaskReadyAges, RoundRobinToken, 
                                   tid_, task, HasWork, I_, J, K, L, kq_out, 
                                   current_time, lqbuf, wr, tid, I, fildes_, 
                                   Steps_, fildes, Steps, PolledRead >>

CheckHasWork(self) == /\ pc[self] = "CheckHasWork"
                      /\ IF HasWork[self] = FALSE
                            THEN /\ pc' = [pc EXCEPT ![self] = "AttemptEnqueueFromGlobalLockLQ"]
                            ELSE /\ pc' = [pc EXCEPT ![self] = "Has_Work_Loop"]
                      /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                      GQPPPointer, GQLock, LQA, LQAClock, 
                                      ClkCycles, LQASizes, LQB, LQBSizes, 
                                      LQLocks, TaskIdCurrent, TasksFinished, 
                                      RTStarted, RTStopped, Futures, 
                                      FuturePush, FuturesBlocked, 
                                      FutureWorkers, FDReadsAvailable, 
                                      FDWritesAvailable, KQueues, 
                                      TaskReadyAges, RoundRobinToken, tid_, 
                                      task, HasWork, I_, J, K, L, kq_out, 
                                      current_time, lqbuf, wr, tid, I, fildes_, 
                                      Steps_, fildes, Steps, PolledRead >>

AttemptEnqueueFromGlobalLockLQ(self) == /\ pc[self] = "AttemptEnqueueFromGlobalLockLQ"
                                        /\ LQLocks[self] = NullLock
                                        /\ LQLocks' = [LQLocks EXCEPT ![self] = self]
                                        /\ K' = [K EXCEPT ![self] = 0]
                                        /\ pc' = [pc EXCEPT ![self] = "AttemptEnqueueFromGlobalLockGQ"]
                                        /\ UNCHANGED << GQA, GQAFirst, GQALast, 
                                                        GQB, GQBSize, 
                                                        GQPPPointer, GQLock, 
                                                        LQA, LQAClock, 
                                                        ClkCycles, LQASizes, 
                                                        LQB, LQBSizes, 
                                                        TaskIdCurrent, 
                                                        TasksFinished, 
                                                        RTStarted, RTStopped, 
                                                        Futures, FuturePush, 
                                                        FuturesBlocked, 
                                                        FutureWorkers, 
                                                        FDReadsAvailable, 
                                                        FDWritesAvailable, 
                                                        KQueues, TaskReadyAges, 
                                                        RoundRobinToken, tid_, 
                                                        task, HasWork, I_, J, 
                                                        L, kq_out, 
                                                        current_time, lqbuf, 
                                                        wr, tid, I, fildes_, 
                                                        Steps_, fildes, Steps, 
                                                        PolledRead >>

AttemptEnqueueFromGlobalLockGQ(self) == /\ pc[self] = "AttemptEnqueueFromGlobalLockGQ"
                                        /\ GQLock = NullLock
                                        /\ GQLock' = self
                                        /\ pc' = [pc EXCEPT ![self] = "GQ_Poll_Check_KQ"]
                                        /\ UNCHANGED << GQA, GQAFirst, GQALast, 
                                                        GQB, GQBSize, 
                                                        GQPPPointer, LQA, 
                                                        LQAClock, ClkCycles, 
                                                        LQASizes, LQB, 
                                                        LQBSizes, LQLocks, 
                                                        TaskIdCurrent, 
                                                        TasksFinished, 
                                                        RTStarted, RTStopped, 
                                                        Futures, FuturePush, 
                                                        FuturesBlocked, 
                                                        FutureWorkers, 
                                                        FDReadsAvailable, 
                                                        FDWritesAvailable, 
                                                        KQueues, TaskReadyAges, 
                                                        RoundRobinToken, tid_, 
                                                        task, HasWork, I_, J, 
                                                        K, L, kq_out, 
                                                        current_time, lqbuf, 
                                                        wr, tid, I, fildes_, 
                                                        Steps_, fildes, Steps, 
                                                        PolledRead >>

GQ_Poll_Check_KQ(self) == /\ pc[self] = "GQ_Poll_Check_KQ"
                          /\ IF KQueues[0] = NullKQ
                                THEN /\ pc' = [pc EXCEPT ![self] = "GQ_Flush_Ready_Begin"]
                                ELSE /\ pc' = [pc EXCEPT ![self] = "GQ_Poll_KQ_Begin"]
                          /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                          GQPPPointer, GQLock, LQA, LQAClock, 
                                          ClkCycles, LQASizes, LQB, LQBSizes, 
                                          LQLocks, TaskIdCurrent, 
                                          TasksFinished, RTStarted, RTStopped, 
                                          Futures, FuturePush, FuturesBlocked, 
                                          FutureWorkers, FDReadsAvailable, 
                                          FDWritesAvailable, KQueues, 
                                          TaskReadyAges, RoundRobinToken, tid_, 
                                          task, HasWork, I_, J, K, L, kq_out, 
                                          current_time, lqbuf, wr, tid, I, 
                                          fildes_, Steps_, fildes, Steps, 
                                          PolledRead >>

GQ_Poll_KQ_Begin(self) == /\ pc[self] = "GQ_Poll_KQ_Begin"
                          /\ kq_out' = [kq_out EXCEPT ![self] = SubSeq(KQueues[0].available, 1, MinNum(KQPollNum, Len(KQueues[0].available)))]
                          /\ KQueues' = [KQueues EXCEPT ![0].available = IF KQPollNum < Len(KQueues[0].available)
                                                                         THEN SubSeq(KQueues[0].available, KQPollNum + 1, Len(KQueues[0].available))
                                                                         ELSE ESeq]
                          /\ pc' = [pc EXCEPT ![self] = "GQ_Update_Ready"]
                          /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                          GQPPPointer, GQLock, LQA, LQAClock, 
                                          ClkCycles, LQASizes, LQB, LQBSizes, 
                                          LQLocks, TaskIdCurrent, 
                                          TasksFinished, RTStarted, RTStopped, 
                                          Futures, FuturePush, FuturesBlocked, 
                                          FutureWorkers, FDReadsAvailable, 
                                          FDWritesAvailable, TaskReadyAges, 
                                          RoundRobinToken, tid_, task, HasWork, 
                                          I_, J, K, L, current_time, lqbuf, wr, 
                                          tid, I, fildes_, Steps_, fildes, 
                                          Steps, PolledRead >>

GQ_Update_Ready(self) == /\ pc[self] = "GQ_Update_Ready"
                         /\ GQB' =    [i \in GQ |->
                                   IF i \in 1..GQBSize /\ \E x \in DOMAIN kq_out[self]: GQB[self][i].t_id = kq_out[self][x].t_id THEN
                                       LET x == CHOOSE x \in DOMAIN kq_out[self]: kq_out[self][x].t_id = LQB[i].t_id
                                       IN
                                           [LQB[i] EXCEPT
                                               !.state = TSReady,
                                               !.blocked_io_info.data = kq_out[self][x].data,
                                               !.blocked_io_info.eof = kq_out[self][x].eof
                                           ]
                                   ELSE GQB[i]]
                         /\ pc' = [pc EXCEPT ![self] = "GQ_Flush_Ready_Begin"]
                         /\ UNCHANGED << GQA, GQAFirst, GQALast, GQBSize, 
                                         GQPPPointer, GQLock, LQA, LQAClock, 
                                         ClkCycles, LQASizes, LQB, LQBSizes, 
                                         LQLocks, TaskIdCurrent, TasksFinished, 
                                         RTStarted, RTStopped, Futures, 
                                         FuturePush, FuturesBlocked, 
                                         FutureWorkers, FDReadsAvailable, 
                                         FDWritesAvailable, KQueues, 
                                         TaskReadyAges, RoundRobinToken, tid_, 
                                         task, HasWork, I_, J, K, L, kq_out, 
                                         current_time, lqbuf, wr, tid, I, 
                                         fildes_, Steps_, fildes, Steps, 
                                         PolledRead >>

GQ_Flush_Ready_Begin(self) == /\ pc[self] = "GQ_Flush_Ready_Begin"
                              /\ I_' = [I_ EXCEPT ![self] = 1]
                              /\ K' = [K EXCEPT ![self] = 0]
                              /\ pc' = [pc EXCEPT ![self] = "GQ_Flush_Ready"]
                              /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                              GQBSize, GQPPPointer, GQLock, 
                                              LQA, LQAClock, ClkCycles, 
                                              LQASizes, LQB, LQBSizes, LQLocks, 
                                              TaskIdCurrent, TasksFinished, 
                                              RTStarted, RTStopped, Futures, 
                                              FuturePush, FuturesBlocked, 
                                              FutureWorkers, FDReadsAvailable, 
                                              FDWritesAvailable, KQueues, 
                                              TaskReadyAges, RoundRobinToken, 
                                              tid_, task, HasWork, J, L, 
                                              kq_out, current_time, lqbuf, wr, 
                                              tid, I, fildes_, Steps_, fildes, 
                                              Steps, PolledRead >>

GQ_Flush_Ready(self) == /\ pc[self] = "GQ_Flush_Ready"
                        /\ IF I_[self] <= GQBSize
                              THEN /\ pc' = [pc EXCEPT ![self] = "GQ_Flush_Check_Timer"]
                              ELSE /\ pc' = [pc EXCEPT ![self] = "GQ_Flush_Ready_Done"]
                        /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                        GQPPPointer, GQLock, LQA, LQAClock, 
                                        ClkCycles, LQASizes, LQB, LQBSizes, 
                                        LQLocks, TaskIdCurrent, TasksFinished, 
                                        RTStarted, RTStopped, Futures, 
                                        FuturePush, FuturesBlocked, 
                                        FutureWorkers, FDReadsAvailable, 
                                        FDWritesAvailable, KQueues, 
                                        TaskReadyAges, RoundRobinToken, tid_, 
                                        task, HasWork, I_, J, K, L, kq_out, 
                                        current_time, lqbuf, wr, tid, I, 
                                        fildes_, Steps_, fildes, Steps, 
                                        PolledRead >>

GQ_Flush_Check_Timer(self) == /\ pc[self] = "GQ_Flush_Check_Timer"
                              /\ IF GQB[I_[self]].state = TSBTimer
                                    THEN /\ \/ /\ GQB' = [GQB EXCEPT ![I_[self]].state = TSReady]
                                            \/ /\ TRUE
                                               /\ GQB' = GQB
                                    ELSE /\ TRUE
                                         /\ GQB' = GQB
                              /\ pc' = [pc EXCEPT ![self] = "GQ_Flush_Ready_Check_Ready"]
                              /\ UNCHANGED << GQA, GQAFirst, GQALast, GQBSize, 
                                              GQPPPointer, GQLock, LQA, 
                                              LQAClock, ClkCycles, LQASizes, 
                                              LQB, LQBSizes, LQLocks, 
                                              TaskIdCurrent, TasksFinished, 
                                              RTStarted, RTStopped, Futures, 
                                              FuturePush, FuturesBlocked, 
                                              FutureWorkers, FDReadsAvailable, 
                                              FDWritesAvailable, KQueues, 
                                              TaskReadyAges, RoundRobinToken, 
                                              tid_, task, HasWork, I_, J, K, L, 
                                              kq_out, current_time, lqbuf, wr, 
                                              tid, I, fildes_, Steps_, fildes, 
                                              Steps, PolledRead >>

GQ_Flush_Ready_Check_Ready(self) == /\ pc[self] = "GQ_Flush_Ready_Check_Ready"
                                    /\ IF GQB[I_[self]].state = TSReady
                                          THEN /\ GQALast' = GQALast + 1
                                               /\ GQA' = [GQA EXCEPT ![((GQALast' - 1) % GQSize) + 1] = GQB[I_[self]]]
                                               /\ TaskReadyAges' = [TaskReadyAges EXCEPT ![GQB[I_[self]].t_id] = 0]
                                               /\ UNCHANGED << GQB, K >>
                                          ELSE /\ K' = [K EXCEPT ![self] = K[self] + 1]
                                               /\ GQB' = [GQB EXCEPT ![K'[self]] = GQB[I_[self]]]
                                               /\ UNCHANGED << GQA, GQALast, 
                                                               TaskReadyAges >>
                                    /\ pc' = [pc EXCEPT ![self] = "GQ_Flush_Ready_Step"]
                                    /\ UNCHANGED << GQAFirst, GQBSize, 
                                                    GQPPPointer, GQLock, LQA, 
                                                    LQAClock, ClkCycles, 
                                                    LQASizes, LQB, LQBSizes, 
                                                    LQLocks, TaskIdCurrent, 
                                                    TasksFinished, RTStarted, 
                                                    RTStopped, Futures, 
                                                    FuturePush, FuturesBlocked, 
                                                    FutureWorkers, 
                                                    FDReadsAvailable, 
                                                    FDWritesAvailable, KQueues, 
                                                    RoundRobinToken, tid_, 
                                                    task, HasWork, I_, J, L, 
                                                    kq_out, current_time, 
                                                    lqbuf, wr, tid, I, fildes_, 
                                                    Steps_, fildes, Steps, 
                                                    PolledRead >>

GQ_Flush_Ready_Step(self) == /\ pc[self] = "GQ_Flush_Ready_Step"
                             /\ I_' = [I_ EXCEPT ![self] = I_[self] + 1]
                             /\ pc' = [pc EXCEPT ![self] = "GQ_Flush_Ready"]
                             /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                             GQBSize, GQPPPointer, GQLock, LQA, 
                                             LQAClock, ClkCycles, LQASizes, 
                                             LQB, LQBSizes, LQLocks, 
                                             TaskIdCurrent, TasksFinished, 
                                             RTStarted, RTStopped, Futures, 
                                             FuturePush, FuturesBlocked, 
                                             FutureWorkers, FDReadsAvailable, 
                                             FDWritesAvailable, KQueues, 
                                             TaskReadyAges, RoundRobinToken, 
                                             tid_, task, HasWork, J, K, L, 
                                             kq_out, current_time, lqbuf, wr, 
                                             tid, I, fildes_, Steps_, fildes, 
                                             Steps, PolledRead >>

GQ_Flush_Ready_Done(self) == /\ pc[self] = "GQ_Flush_Ready_Done"
                             /\ GQBSize' = K[self]
                             /\ I_' = [I_ EXCEPT ![self] = GQAFirst + 1]
                             /\ K' = [K EXCEPT ![self] = 0]
                             /\ pc' = [pc EXCEPT ![self] = "AttemptEnqueueFromGlobalWhile"]
                             /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                             GQPPPointer, GQLock, LQA, 
                                             LQAClock, ClkCycles, LQASizes, 
                                             LQB, LQBSizes, LQLocks, 
                                             TaskIdCurrent, TasksFinished, 
                                             RTStarted, RTStopped, Futures, 
                                             FuturePush, FuturesBlocked, 
                                             FutureWorkers, FDReadsAvailable, 
                                             FDWritesAvailable, KQueues, 
                                             TaskReadyAges, RoundRobinToken, 
                                             tid_, task, HasWork, J, L, kq_out, 
                                             current_time, lqbuf, wr, tid, I, 
                                             fildes_, Steps_, fildes, Steps, 
                                             PolledRead >>

AttemptEnqueueFromGlobalWhile(self) == /\ pc[self] = "AttemptEnqueueFromGlobalWhile"
                                       /\ IF I_[self] <= GQALast /\ K[self] < (LQSize \div 2)
                                             THEN /\ K' = [K EXCEPT ![self] = K[self] + 1]
                                                  /\ LQA' = [LQA EXCEPT ![self][K'[self]] = GQA[I_[self]]]
                                                  /\ I_' = [I_ EXCEPT ![self] = I_[self] + 1]
                                                  /\ pc' = [pc EXCEPT ![self] = "AttemptEnqueueFromGlobalWhile"]
                                             ELSE /\ pc' = [pc EXCEPT ![self] = "UpdateGQAPointers"]
                                                  /\ UNCHANGED << LQA, I_, K >>
                                       /\ UNCHANGED << GQA, GQAFirst, GQALast, 
                                                       GQB, GQBSize, 
                                                       GQPPPointer, GQLock, 
                                                       LQAClock, ClkCycles, 
                                                       LQASizes, LQB, LQBSizes, 
                                                       LQLocks, TaskIdCurrent, 
                                                       TasksFinished, 
                                                       RTStarted, RTStopped, 
                                                       Futures, FuturePush, 
                                                       FuturesBlocked, 
                                                       FutureWorkers, 
                                                       FDReadsAvailable, 
                                                       FDWritesAvailable, 
                                                       KQueues, TaskReadyAges, 
                                                       RoundRobinToken, tid_, 
                                                       task, HasWork, J, L, 
                                                       kq_out, current_time, 
                                                       lqbuf, wr, tid, I, 
                                                       fildes_, Steps_, fildes, 
                                                       Steps, PolledRead >>

UpdateGQAPointers(self) == /\ pc[self] = "UpdateGQAPointers"
                           /\ GQAFirst' = I_[self] - 1
                           /\ pc' = [pc EXCEPT ![self] = "UpdateGQAPointersCheck"]
                           /\ UNCHANGED << GQA, GQALast, GQB, GQBSize, 
                                           GQPPPointer, GQLock, LQA, LQAClock, 
                                           ClkCycles, LQASizes, LQB, LQBSizes, 
                                           LQLocks, TaskIdCurrent, 
                                           TasksFinished, RTStarted, RTStopped, 
                                           Futures, FuturePush, FuturesBlocked, 
                                           FutureWorkers, FDReadsAvailable, 
                                           FDWritesAvailable, KQueues, 
                                           TaskReadyAges, RoundRobinToken, 
                                           tid_, task, HasWork, I_, J, K, L, 
                                           kq_out, current_time, lqbuf, wr, 
                                           tid, I, fildes_, Steps_, fildes, 
                                           Steps, PolledRead >>

UpdateGQAPointersCheck(self) == /\ pc[self] = "UpdateGQAPointersCheck"
                                /\ IF GQAFirst > GQSize
                                      THEN /\ GQAFirst' = GQAFirst - GQSize
                                           /\ GQALast' = GQALast - GQSize
                                           /\ GQPPPointer' = GQPPPointer - GQSize
                                      ELSE /\ TRUE
                                           /\ UNCHANGED << GQAFirst, GQALast, 
                                                           GQPPPointer >>
                                /\ pc' = [pc EXCEPT ![self] = "AttemptEnqueueFromGlobalFinish"]
                                /\ UNCHANGED << GQA, GQB, GQBSize, GQLock, LQA, 
                                                LQAClock, ClkCycles, LQASizes, 
                                                LQB, LQBSizes, LQLocks, 
                                                TaskIdCurrent, TasksFinished, 
                                                RTStarted, RTStopped, Futures, 
                                                FuturePush, FuturesBlocked, 
                                                FutureWorkers, 
                                                FDReadsAvailable, 
                                                FDWritesAvailable, KQueues, 
                                                TaskReadyAges, RoundRobinToken, 
                                                tid_, task, HasWork, I_, J, K, 
                                                L, kq_out, current_time, lqbuf, 
                                                wr, tid, I, fildes_, Steps_, 
                                                fildes, Steps, PolledRead >>

AttemptEnqueueFromGlobalFinish(self) == /\ pc[self] = "AttemptEnqueueFromGlobalFinish"
                                        /\ GQLock' = NullLock
                                        /\ LQASizes' = [LQASizes EXCEPT ![self] = K[self]]
                                        /\ LQLocks' = [LQLocks EXCEPT ![self] = NullLock]
                                        /\ pc' = [pc EXCEPT ![self] = "EnqueueFromGlobalCheck"]
                                        /\ UNCHANGED << GQA, GQAFirst, GQALast, 
                                                        GQB, GQBSize, 
                                                        GQPPPointer, LQA, 
                                                        LQAClock, ClkCycles, 
                                                        LQB, LQBSizes, 
                                                        TaskIdCurrent, 
                                                        TasksFinished, 
                                                        RTStarted, RTStopped, 
                                                        Futures, FuturePush, 
                                                        FuturesBlocked, 
                                                        FutureWorkers, 
                                                        FDReadsAvailable, 
                                                        FDWritesAvailable, 
                                                        KQueues, TaskReadyAges, 
                                                        RoundRobinToken, tid_, 
                                                        task, HasWork, I_, J, 
                                                        K, L, kq_out, 
                                                        current_time, lqbuf, 
                                                        wr, tid, I, fildes_, 
                                                        Steps_, fildes, Steps, 
                                                        PolledRead >>

EnqueueFromGlobalCheck(self) == /\ pc[self] = "EnqueueFromGlobalCheck"
                                /\ IF K[self] > 0
                                      THEN /\ pc' = [pc EXCEPT ![self] = "Main_Loop"]
                                      ELSE /\ pc' = [pc EXCEPT ![self] = "WorkStealingBegin"]
                                /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                                GQBSize, GQPPPointer, GQLock, 
                                                LQA, LQAClock, ClkCycles, 
                                                LQASizes, LQB, LQBSizes, 
                                                LQLocks, TaskIdCurrent, 
                                                TasksFinished, RTStarted, 
                                                RTStopped, Futures, FuturePush, 
                                                FuturesBlocked, FutureWorkers, 
                                                FDReadsAvailable, 
                                                FDWritesAvailable, KQueues, 
                                                TaskReadyAges, RoundRobinToken, 
                                                tid_, task, HasWork, I_, J, K, 
                                                L, kq_out, current_time, lqbuf, 
                                                wr, tid, I, fildes_, Steps_, 
                                                fildes, Steps, PolledRead >>

WorkStealingBegin(self) == /\ pc[self] = "WorkStealingBegin"
                           /\ I_' = [I_ EXCEPT ![self] = 1]
                           /\ pc' = [pc EXCEPT ![self] = "WorkStealingMainLoop"]
                           /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                           GQBSize, GQPPPointer, GQLock, LQA, 
                                           LQAClock, ClkCycles, LQASizes, LQB, 
                                           LQBSizes, LQLocks, TaskIdCurrent, 
                                           TasksFinished, RTStarted, RTStopped, 
                                           Futures, FuturePush, FuturesBlocked, 
                                           FutureWorkers, FDReadsAvailable, 
                                           FDWritesAvailable, KQueues, 
                                           TaskReadyAges, RoundRobinToken, 
                                           tid_, task, HasWork, J, K, L, 
                                           kq_out, current_time, lqbuf, wr, 
                                           tid, I, fildes_, Steps_, fildes, 
                                           Steps, PolledRead >>

WorkStealingMainLoop(self) == /\ pc[self] = "WorkStealingMainLoop"
                              /\ IF I_[self] <= NumWorkers
                                    THEN /\ IF I_[self] < self
                                               THEN /\ pc' = [pc EXCEPT ![self] = "WorkStealingAcquireSelfLock"]
                                               ELSE /\ IF I_[self] > self
                                                          THEN /\ pc' = [pc EXCEPT ![self] = "WorkStealingAcquireVictimLock2"]
                                                          ELSE /\ pc' = [pc EXCEPT ![self] = "WorkStealingFinishedStolen"]
                                    ELSE /\ pc' = [pc EXCEPT ![self] = "No_Tasks"]
                              /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                              GQBSize, GQPPPointer, GQLock, 
                                              LQA, LQAClock, ClkCycles, 
                                              LQASizes, LQB, LQBSizes, LQLocks, 
                                              TaskIdCurrent, TasksFinished, 
                                              RTStarted, RTStopped, Futures, 
                                              FuturePush, FuturesBlocked, 
                                              FutureWorkers, FDReadsAvailable, 
                                              FDWritesAvailable, KQueues, 
                                              TaskReadyAges, RoundRobinToken, 
                                              tid_, task, HasWork, I_, J, K, L, 
                                              kq_out, current_time, lqbuf, wr, 
                                              tid, I, fildes_, Steps_, fildes, 
                                              Steps, PolledRead >>

WorkStealingFinishedStolen(self) == /\ pc[self] = "WorkStealingFinishedStolen"
                                    /\ IF K[self] > 0
                                          THEN /\ pc' = [pc EXCEPT ![self] = "Main_Loop"]
                                          ELSE /\ pc' = [pc EXCEPT ![self] = "WorkStealingLoopStep"]
                                    /\ UNCHANGED << GQA, GQAFirst, GQALast, 
                                                    GQB, GQBSize, GQPPPointer, 
                                                    GQLock, LQA, LQAClock, 
                                                    ClkCycles, LQASizes, LQB, 
                                                    LQBSizes, LQLocks, 
                                                    TaskIdCurrent, 
                                                    TasksFinished, RTStarted, 
                                                    RTStopped, Futures, 
                                                    FuturePush, FuturesBlocked, 
                                                    FutureWorkers, 
                                                    FDReadsAvailable, 
                                                    FDWritesAvailable, KQueues, 
                                                    TaskReadyAges, 
                                                    RoundRobinToken, tid_, 
                                                    task, HasWork, I_, J, K, L, 
                                                    kq_out, current_time, 
                                                    lqbuf, wr, tid, I, fildes_, 
                                                    Steps_, fildes, Steps, 
                                                    PolledRead >>

WorkStealingLoopStep(self) == /\ pc[self] = "WorkStealingLoopStep"
                              /\ I_' = [I_ EXCEPT ![self] = I_[self] + 1]
                              /\ pc' = [pc EXCEPT ![self] = "WorkStealingMainLoop"]
                              /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                              GQBSize, GQPPPointer, GQLock, 
                                              LQA, LQAClock, ClkCycles, 
                                              LQASizes, LQB, LQBSizes, LQLocks, 
                                              TaskIdCurrent, TasksFinished, 
                                              RTStarted, RTStopped, Futures, 
                                              FuturePush, FuturesBlocked, 
                                              FutureWorkers, FDReadsAvailable, 
                                              FDWritesAvailable, KQueues, 
                                              TaskReadyAges, RoundRobinToken, 
                                              tid_, task, HasWork, J, K, L, 
                                              kq_out, current_time, lqbuf, wr, 
                                              tid, I, fildes_, Steps_, fildes, 
                                              Steps, PolledRead >>

WorkStealingAcquireSelfLock(self) == /\ pc[self] = "WorkStealingAcquireSelfLock"
                                     /\ LQLocks[self] = NullLock
                                     /\ LQLocks' = [LQLocks EXCEPT ![self] = self]
                                     /\ pc' = [pc EXCEPT ![self] = "WorkStealingAcquireVictimLock"]
                                     /\ UNCHANGED << GQA, GQAFirst, GQALast, 
                                                     GQB, GQBSize, GQPPPointer, 
                                                     GQLock, LQA, LQAClock, 
                                                     ClkCycles, LQASizes, LQB, 
                                                     LQBSizes, TaskIdCurrent, 
                                                     TasksFinished, RTStarted, 
                                                     RTStopped, Futures, 
                                                     FuturePush, 
                                                     FuturesBlocked, 
                                                     FutureWorkers, 
                                                     FDReadsAvailable, 
                                                     FDWritesAvailable, 
                                                     KQueues, TaskReadyAges, 
                                                     RoundRobinToken, tid_, 
                                                     task, HasWork, I_, J, K, 
                                                     L, kq_out, current_time, 
                                                     lqbuf, wr, tid, I, 
                                                     fildes_, Steps_, fildes, 
                                                     Steps, PolledRead >>

WorkStealingAcquireVictimLock(self) == /\ pc[self] = "WorkStealingAcquireVictimLock"
                                       /\ LQLocks[I_[self]] = NullLock
                                       /\ LQLocks' = [LQLocks EXCEPT ![I_[self]] = self]
                                       /\ pc' = [pc EXCEPT ![self] = "WorkstealingCheck1"]
                                       /\ UNCHANGED << GQA, GQAFirst, GQALast, 
                                                       GQB, GQBSize, 
                                                       GQPPPointer, GQLock, 
                                                       LQA, LQAClock, 
                                                       ClkCycles, LQASizes, 
                                                       LQB, LQBSizes, 
                                                       TaskIdCurrent, 
                                                       TasksFinished, 
                                                       RTStarted, RTStopped, 
                                                       Futures, FuturePush, 
                                                       FuturesBlocked, 
                                                       FutureWorkers, 
                                                       FDReadsAvailable, 
                                                       FDWritesAvailable, 
                                                       KQueues, TaskReadyAges, 
                                                       RoundRobinToken, tid_, 
                                                       task, HasWork, I_, J, K, 
                                                       L, kq_out, current_time, 
                                                       lqbuf, wr, tid, I, 
                                                       fildes_, Steps_, fildes, 
                                                       Steps, PolledRead >>

WorkstealingCheck1(self) == /\ pc[self] = "WorkstealingCheck1"
                            /\ IF LQASizes[I_[self]] < 2
                                  THEN /\ pc' = [pc EXCEPT ![self] = "WorkStealingFinishedStolen1"]
                                  ELSE /\ pc' = [pc EXCEPT ![self] = "WorkStealingCont1"]
                            /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                            GQBSize, GQPPPointer, GQLock, LQA, 
                                            LQAClock, ClkCycles, LQASizes, LQB, 
                                            LQBSizes, LQLocks, TaskIdCurrent, 
                                            TasksFinished, RTStarted, 
                                            RTStopped, Futures, FuturePush, 
                                            FuturesBlocked, FutureWorkers, 
                                            FDReadsAvailable, 
                                            FDWritesAvailable, KQueues, 
                                            TaskReadyAges, RoundRobinToken, 
                                            tid_, task, HasWork, I_, J, K, L, 
                                            kq_out, current_time, lqbuf, wr, 
                                            tid, I, fildes_, Steps_, fildes, 
                                            Steps, PolledRead >>

WorkStealingCont1(self) == /\ pc[self] = "WorkStealingCont1"
                           /\ J' = [J EXCEPT ![self] = LQAClock[I_[self]] + 1]
                           /\ K' = [K EXCEPT ![self] = 0]
                           /\ pc' = [pc EXCEPT ![self] = "WorkstealingSteal"]
                           /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                           GQBSize, GQPPPointer, GQLock, LQA, 
                                           LQAClock, ClkCycles, LQASizes, LQB, 
                                           LQBSizes, LQLocks, TaskIdCurrent, 
                                           TasksFinished, RTStarted, RTStopped, 
                                           Futures, FuturePush, FuturesBlocked, 
                                           FutureWorkers, FDReadsAvailable, 
                                           FDWritesAvailable, KQueues, 
                                           TaskReadyAges, RoundRobinToken, 
                                           tid_, task, HasWork, I_, L, kq_out, 
                                           current_time, lqbuf, wr, tid, I, 
                                           fildes_, Steps_, fildes, Steps, 
                                           PolledRead >>

WorkstealingSteal(self) == /\ pc[self] = "WorkstealingSteal"
                           /\ IF J[self] < LQASizes[I_[self]]
                                 THEN /\ IF LQA[I_[self]][J[self]] # NullTask /\ LQA[I_[self]][J[self]].state = TSReady
                                            THEN /\ K' = [K EXCEPT ![self] = K[self] + 1]
                                                 /\ LQA' = [LQA EXCEPT ![self][K'[self]] = LQA[I_[self]][J[self]], ![I_[self]][J[self]] = NullTask]
                                                 /\ IF K'[self] > LQASizes[I_[self]] \div 2
                                                       THEN /\ pc' = [pc EXCEPT ![self] = "WorkStealingFinishedStolen1"]
                                                       ELSE /\ pc' = [pc EXCEPT ![self] = "WorkstealingSteal"]
                                            ELSE /\ pc' = [pc EXCEPT ![self] = "WorkstealingSteal"]
                                                 /\ UNCHANGED << LQA, K >>
                                 ELSE /\ pc' = [pc EXCEPT ![self] = "WorkStealingFinishedStolen1"]
                                      /\ UNCHANGED << LQA, K >>
                           /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                           GQBSize, GQPPPointer, GQLock, 
                                           LQAClock, ClkCycles, LQASizes, LQB, 
                                           LQBSizes, LQLocks, TaskIdCurrent, 
                                           TasksFinished, RTStarted, RTStopped, 
                                           Futures, FuturePush, FuturesBlocked, 
                                           FutureWorkers, FDReadsAvailable, 
                                           FDWritesAvailable, KQueues, 
                                           TaskReadyAges, RoundRobinToken, 
                                           tid_, task, HasWork, I_, J, L, 
                                           kq_out, current_time, lqbuf, wr, 
                                           tid, I, fildes_, Steps_, fildes, 
                                           Steps, PolledRead >>

WorkStealingFinishedStolen1(self) == /\ pc[self] = "WorkStealingFinishedStolen1"
                                     /\ LQLocks' = [LQLocks EXCEPT ![I_[self]] = NullLock, ![self] = NullLock]
                                     /\ LQASizes' = [LQASizes EXCEPT ![self] = K[self]]
                                     /\ LQAClock' = [LQAClock EXCEPT ![self] = K[self] + 1]
                                     /\ pc' = [pc EXCEPT ![self] = "WorkStealingFinishedStolen"]
                                     /\ UNCHANGED << GQA, GQAFirst, GQALast, 
                                                     GQB, GQBSize, GQPPPointer, 
                                                     GQLock, LQA, ClkCycles, 
                                                     LQB, LQBSizes, 
                                                     TaskIdCurrent, 
                                                     TasksFinished, RTStarted, 
                                                     RTStopped, Futures, 
                                                     FuturePush, 
                                                     FuturesBlocked, 
                                                     FutureWorkers, 
                                                     FDReadsAvailable, 
                                                     FDWritesAvailable, 
                                                     KQueues, TaskReadyAges, 
                                                     RoundRobinToken, tid_, 
                                                     task, HasWork, I_, J, K, 
                                                     L, kq_out, current_time, 
                                                     lqbuf, wr, tid, I, 
                                                     fildes_, Steps_, fildes, 
                                                     Steps, PolledRead >>

WorkStealingAcquireVictimLock2(self) == /\ pc[self] = "WorkStealingAcquireVictimLock2"
                                        /\ LQLocks[I_[self]] = NullLock
                                        /\ LQLocks' = [LQLocks EXCEPT ![I_[self]] = self]
                                        /\ pc' = [pc EXCEPT ![self] = "WorkstealingCheck2"]
                                        /\ UNCHANGED << GQA, GQAFirst, GQALast, 
                                                        GQB, GQBSize, 
                                                        GQPPPointer, GQLock, 
                                                        LQA, LQAClock, 
                                                        ClkCycles, LQASizes, 
                                                        LQB, LQBSizes, 
                                                        TaskIdCurrent, 
                                                        TasksFinished, 
                                                        RTStarted, RTStopped, 
                                                        Futures, FuturePush, 
                                                        FuturesBlocked, 
                                                        FutureWorkers, 
                                                        FDReadsAvailable, 
                                                        FDWritesAvailable, 
                                                        KQueues, TaskReadyAges, 
                                                        RoundRobinToken, tid_, 
                                                        task, HasWork, I_, J, 
                                                        K, L, kq_out, 
                                                        current_time, lqbuf, 
                                                        wr, tid, I, fildes_, 
                                                        Steps_, fildes, Steps, 
                                                        PolledRead >>

WorkstealingCheck2(self) == /\ pc[self] = "WorkstealingCheck2"
                            /\ IF LQASizes[I_[self]] < 2
                                  THEN /\ pc' = [pc EXCEPT ![self] = "WorkStealingUnlockVictimLock2"]
                                  ELSE /\ pc' = [pc EXCEPT ![self] = "WorkStealingCont2"]
                            /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                            GQBSize, GQPPPointer, GQLock, LQA, 
                                            LQAClock, ClkCycles, LQASizes, LQB, 
                                            LQBSizes, LQLocks, TaskIdCurrent, 
                                            TasksFinished, RTStarted, 
                                            RTStopped, Futures, FuturePush, 
                                            FuturesBlocked, FutureWorkers, 
                                            FDReadsAvailable, 
                                            FDWritesAvailable, KQueues, 
                                            TaskReadyAges, RoundRobinToken, 
                                            tid_, task, HasWork, I_, J, K, L, 
                                            kq_out, current_time, lqbuf, wr, 
                                            tid, I, fildes_, Steps_, fildes, 
                                            Steps, PolledRead >>

WorkStealingCont2(self) == /\ pc[self] = "WorkStealingCont2"
                           /\ J' = [J EXCEPT ![self] = LQAClock[I_[self]] + 1]
                           /\ K' = [K EXCEPT ![self] = 0]
                           /\ pc' = [pc EXCEPT ![self] = "WorkstealingSteal2"]
                           /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                           GQBSize, GQPPPointer, GQLock, LQA, 
                                           LQAClock, ClkCycles, LQASizes, LQB, 
                                           LQBSizes, LQLocks, TaskIdCurrent, 
                                           TasksFinished, RTStarted, RTStopped, 
                                           Futures, FuturePush, FuturesBlocked, 
                                           FutureWorkers, FDReadsAvailable, 
                                           FDWritesAvailable, KQueues, 
                                           TaskReadyAges, RoundRobinToken, 
                                           tid_, task, HasWork, I_, L, kq_out, 
                                           current_time, lqbuf, wr, tid, I, 
                                           fildes_, Steps_, fildes, Steps, 
                                           PolledRead >>

WorkstealingSteal2(self) == /\ pc[self] = "WorkstealingSteal2"
                            /\ IF J[self] < LQASizes[I_[self]]
                                  THEN /\ IF LQA[I_[self]][J[self]] # NullTask /\ LQA[I_[self]][J[self]].state = TSReady
                                             THEN /\ K' = [K EXCEPT ![self] = K[self] + 1]
                                                  /\ lqbuf' = [lqbuf EXCEPT ![self][K'[self]] = LQA[I_[self]][J[self]]]
                                                  /\ LQA' = [LQA EXCEPT ![I_[self]][J[self]] = NullTask]
                                                  /\ IF K'[self] > LQASizes[I_[self]] \div 2
                                                        THEN /\ pc' = [pc EXCEPT ![self] = "WorkStealingUnlockVictimLock2"]
                                                        ELSE /\ pc' = [pc EXCEPT ![self] = "WorkstealingSteal2"]
                                             ELSE /\ pc' = [pc EXCEPT ![self] = "WorkstealingSteal2"]
                                                  /\ UNCHANGED << LQA, K, 
                                                                  lqbuf >>
                                  ELSE /\ pc' = [pc EXCEPT ![self] = "WorkStealingUnlockVictimLock2"]
                                       /\ UNCHANGED << LQA, K, lqbuf >>
                            /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                            GQBSize, GQPPPointer, GQLock, 
                                            LQAClock, ClkCycles, LQASizes, LQB, 
                                            LQBSizes, LQLocks, TaskIdCurrent, 
                                            TasksFinished, RTStarted, 
                                            RTStopped, Futures, FuturePush, 
                                            FuturesBlocked, FutureWorkers, 
                                            FDReadsAvailable, 
                                            FDWritesAvailable, KQueues, 
                                            TaskReadyAges, RoundRobinToken, 
                                            tid_, task, HasWork, I_, J, L, 
                                            kq_out, current_time, wr, tid, I, 
                                            fildes_, Steps_, fildes, Steps, 
                                            PolledRead >>

WorkStealingUnlockVictimLock2(self) == /\ pc[self] = "WorkStealingUnlockVictimLock2"
                                       /\ LQLocks' = [LQLocks EXCEPT ![I_[self]] = NullLock]
                                       /\ LQA' = [LQA EXCEPT ![self] = lqbuf[self]]
                                       /\ LQASizes' = [LQASizes EXCEPT ![self] = K[self]]
                                       /\ LQAClock' = [LQAClock EXCEPT ![self] = K[self] + 1]
                                       /\ pc' = [pc EXCEPT ![self] = "WorkStealingFinishedStolen"]
                                       /\ UNCHANGED << GQA, GQAFirst, GQALast, 
                                                       GQB, GQBSize, 
                                                       GQPPPointer, GQLock, 
                                                       ClkCycles, LQB, 
                                                       LQBSizes, TaskIdCurrent, 
                                                       TasksFinished, 
                                                       RTStarted, RTStopped, 
                                                       Futures, FuturePush, 
                                                       FuturesBlocked, 
                                                       FutureWorkers, 
                                                       FDReadsAvailable, 
                                                       FDWritesAvailable, 
                                                       KQueues, TaskReadyAges, 
                                                       RoundRobinToken, tid_, 
                                                       task, HasWork, I_, J, K, 
                                                       L, kq_out, current_time, 
                                                       lqbuf, wr, tid, I, 
                                                       fildes_, Steps_, fildes, 
                                                       Steps, PolledRead >>

No_Tasks(self) == /\ pc[self] = "No_Tasks"
                  /\ pc' = [pc EXCEPT ![self] = "Main_Loop"]
                  /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                  GQPPPointer, GQLock, LQA, LQAClock, 
                                  ClkCycles, LQASizes, LQB, LQBSizes, LQLocks, 
                                  TaskIdCurrent, TasksFinished, RTStarted, 
                                  RTStopped, Futures, FuturePush, 
                                  FuturesBlocked, FutureWorkers, 
                                  FDReadsAvailable, FDWritesAvailable, KQueues, 
                                  TaskReadyAges, RoundRobinToken, tid_, task, 
                                  HasWork, I_, J, K, L, kq_out, current_time, 
                                  lqbuf, wr, tid, I, fildes_, Steps_, fildes, 
                                  Steps, PolledRead >>

Has_Work_Loop(self) == /\ pc[self] = "Has_Work_Loop"
                       /\ IF HasWork[self] = TRUE
                             THEN /\ pc' = [pc EXCEPT ![self] = "DoFuturePoll"]
                             ELSE /\ pc' = [pc EXCEPT ![self] = "Main_Loop"]
                       /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                       GQPPPointer, GQLock, LQA, LQAClock, 
                                       ClkCycles, LQASizes, LQB, LQBSizes, 
                                       LQLocks, TaskIdCurrent, TasksFinished, 
                                       RTStarted, RTStopped, Futures, 
                                       FuturePush, FuturesBlocked, 
                                       FutureWorkers, FDReadsAvailable, 
                                       FDWritesAvailable, KQueues, 
                                       TaskReadyAges, RoundRobinToken, tid_, 
                                       task, HasWork, I_, J, K, L, kq_out, 
                                       current_time, lqbuf, wr, tid, I, 
                                       fildes_, Steps_, fildes, Steps, 
                                       PolledRead >>

DoFuturePoll(self) == /\ pc[self] = "DoFuturePoll"
                      /\ RoundRobinToken = self
                      /\ TaskReadyAges' = [x \in DOMAIN TaskReadyAges |-> IF TaskReadyAges[x] = NullTRA THEN NullTRA ELSE TaskReadyAges[x] + 1]
                      /\ RoundRobinToken' = (IF self + 1 \in Workers THEN self + 1 ELSE 1)
                      /\ FutureWorkers' = [FutureWorkers EXCEPT ![task[self].future] = self]
                      /\ FuturesBlocked' = [FuturesBlocked EXCEPT ![task[self].future] = NullFB]
                      /\ Futures' = [Futures EXCEPT ![task[self].future] = FSPolling]
                      /\ pc' = [pc EXCEPT ![self] = "ProcessStatus"]
                      /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                      GQPPPointer, GQLock, LQA, LQAClock, 
                                      ClkCycles, LQASizes, LQB, LQBSizes, 
                                      LQLocks, TaskIdCurrent, TasksFinished, 
                                      RTStarted, RTStopped, FuturePush, 
                                      FDReadsAvailable, FDWritesAvailable, 
                                      KQueues, tid_, task, HasWork, I_, J, K, 
                                      L, kq_out, current_time, lqbuf, wr, tid, 
                                      I, fildes_, Steps_, fildes, Steps, 
                                      PolledRead >>

ProcessStatus(self) == /\ pc[self] = "ProcessStatus"
                       /\ Futures[task[self].future] # FSPolling
                       /\ pc' = [pc EXCEPT ![self] = "ProcessStatusInLQ"]
                       /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                       GQPPPointer, GQLock, LQA, LQAClock, 
                                       ClkCycles, LQASizes, LQB, LQBSizes, 
                                       LQLocks, TaskIdCurrent, TasksFinished, 
                                       RTStarted, RTStopped, Futures, 
                                       FuturePush, FuturesBlocked, 
                                       FutureWorkers, FDReadsAvailable, 
                                       FDWritesAvailable, KQueues, 
                                       TaskReadyAges, RoundRobinToken, tid_, 
                                       task, HasWork, I_, J, K, L, kq_out, 
                                       current_time, lqbuf, wr, tid, I, 
                                       fildes_, Steps_, fildes, Steps, 
                                       PolledRead >>

ProcessStatusInLQ(self) == /\ pc[self] = "ProcessStatusInLQ"
                           /\ LQLocks[self] = NullLock
                           /\ LQLocks' = [LQLocks EXCEPT ![self] = self]
                           /\ IF Futures[task[self].future] = FSReturned
                                 THEN /\ IF FuturesBlocked[task[self].future] # NullFB
                                            THEN /\ IF FuturesBlocked[task[self].future].kind \in {FBKindRead, FBKindWrite}
                                                       THEN /\ LQA' = [LQA EXCEPT ![self][LQAClock[self]] = [LQA[self][LQAClock[self]] EXCEPT !.state = TSBIO, !.blocked_io_info = [fd |-> FuturesBlocked[task[self].future].fd, ty |-> FuturesBlocked[task[self].future].kind, data |-> 0, eof |-> FALSE]]]
                                                            /\ TaskReadyAges' = [TaskReadyAges EXCEPT ![LQA'[self][LQAClock[self]].t_id] = NullTRA]
                                                       ELSE /\ IF FuturesBlocked[task[self].future].kind = FBKindTimer
                                                                  THEN /\ LQA' = [LQA EXCEPT ![self][LQAClock[self]] = [LQA[self][LQAClock[self]] EXCEPT !.state = TSBTimer]]
                                                                       /\ TaskReadyAges' = [TaskReadyAges EXCEPT ![LQA'[self][LQAClock[self]].t_id] = NullTRA]
                                                                  ELSE /\ TRUE
                                                                       /\ UNCHANGED << LQA, 
                                                                                       TaskReadyAges >>
                                            ELSE /\ LQA' = [LQA EXCEPT ![self][LQAClock[self]].state = TSReady]
                                                 /\ TaskReadyAges' = [TaskReadyAges EXCEPT ![LQA'[self][LQAClock[self]].t_id] = 0]
                                      /\ UNCHANGED TasksFinished
                                 ELSE /\ TaskReadyAges' = [TaskReadyAges EXCEPT ![LQA[self][LQAClock[self]].t_id] = NullTRA]
                                      /\ LQA' = [LQA EXCEPT ![self][LQAClock[self]] = NullTask]
                                      /\ TasksFinished' = TasksFinished + 1
                           /\ pc' = [pc EXCEPT ![self] = "LQ_Unlock_AfterProc"]
                           /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                           GQBSize, GQPPPointer, GQLock, 
                                           LQAClock, ClkCycles, LQASizes, LQB, 
                                           LQBSizes, TaskIdCurrent, RTStarted, 
                                           RTStopped, Futures, FuturePush, 
                                           FuturesBlocked, FutureWorkers, 
                                           FDReadsAvailable, FDWritesAvailable, 
                                           KQueues, RoundRobinToken, tid_, 
                                           task, HasWork, I_, J, K, L, kq_out, 
                                           current_time, lqbuf, wr, tid, I, 
                                           fildes_, Steps_, fildes, Steps, 
                                           PolledRead >>

LQ_Unlock_AfterProc(self) == /\ pc[self] = "LQ_Unlock_AfterProc"
                             /\ LQLocks' = [LQLocks EXCEPT ![self] = NullLock]
                             /\ pc' = [pc EXCEPT ![self] = "LQ_Lock2"]
                             /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                             GQBSize, GQPPPointer, GQLock, LQA, 
                                             LQAClock, ClkCycles, LQASizes, 
                                             LQB, LQBSizes, TaskIdCurrent, 
                                             TasksFinished, RTStarted, 
                                             RTStopped, Futures, FuturePush, 
                                             FuturesBlocked, FutureWorkers, 
                                             FDReadsAvailable, 
                                             FDWritesAvailable, KQueues, 
                                             TaskReadyAges, RoundRobinToken, 
                                             tid_, task, HasWork, I_, J, K, L, 
                                             kq_out, current_time, lqbuf, wr, 
                                             tid, I, fildes_, Steps_, fildes, 
                                             Steps, PolledRead >>

LQ_Lock2(self) == /\ pc[self] = "LQ_Lock2"
                  /\ LQLocks[self] = NullLock
                  /\ LQLocks' = [LQLocks EXCEPT ![self] = self]
                  /\ pc' = [pc EXCEPT ![self] = "LQ_Pull2"]
                  /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                  GQPPPointer, GQLock, LQA, LQAClock, 
                                  ClkCycles, LQASizes, LQB, LQBSizes, 
                                  TaskIdCurrent, TasksFinished, RTStarted, 
                                  RTStopped, Futures, FuturePush, 
                                  FuturesBlocked, FutureWorkers, 
                                  FDReadsAvailable, FDWritesAvailable, KQueues, 
                                  TaskReadyAges, RoundRobinToken, tid_, task, 
                                  HasWork, I_, J, K, L, kq_out, current_time, 
                                  lqbuf, wr, tid, I, fildes_, Steps_, fildes, 
                                  Steps, PolledRead >>

LQ_Pull2(self) == /\ pc[self] = "LQ_Pull2"
                  /\ IF LQASizes[self] = 0
                        THEN /\ pc' = [pc EXCEPT ![self] = "LQ_Pull_Empty2"]
                        ELSE /\ pc' = [pc EXCEPT ![self] = "UpdateLQAClock2"]
                  /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                  GQPPPointer, GQLock, LQA, LQAClock, 
                                  ClkCycles, LQASizes, LQB, LQBSizes, LQLocks, 
                                  TaskIdCurrent, TasksFinished, RTStarted, 
                                  RTStopped, Futures, FuturePush, 
                                  FuturesBlocked, FutureWorkers, 
                                  FDReadsAvailable, FDWritesAvailable, KQueues, 
                                  TaskReadyAges, RoundRobinToken, tid_, task, 
                                  HasWork, I_, J, K, L, kq_out, current_time, 
                                  lqbuf, wr, tid, I, fildes_, Steps_, fildes, 
                                  Steps, PolledRead >>

LQ_Pull_Empty2(self) == /\ pc[self] = "LQ_Pull_Empty2"
                        /\ HasWork' = [HasWork EXCEPT ![self] = FALSE]
                        /\ pc' = [pc EXCEPT ![self] = "LQ_Unlock2"]
                        /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                        GQPPPointer, GQLock, LQA, LQAClock, 
                                        ClkCycles, LQASizes, LQB, LQBSizes, 
                                        LQLocks, TaskIdCurrent, TasksFinished, 
                                        RTStarted, RTStopped, Futures, 
                                        FuturePush, FuturesBlocked, 
                                        FutureWorkers, FDReadsAvailable, 
                                        FDWritesAvailable, KQueues, 
                                        TaskReadyAges, RoundRobinToken, tid_, 
                                        task, I_, J, K, L, kq_out, 
                                        current_time, lqbuf, wr, tid, I, 
                                        fildes_, Steps_, fildes, Steps, 
                                        PolledRead >>

UpdateLQAClock2(self) == /\ pc[self] = "UpdateLQAClock2"
                         /\ IF LQAClock[self] = 1
                               THEN /\ HasWork' = [HasWork EXCEPT ![self] = FALSE]
                                    /\ LQLocks' = [LQLocks EXCEPT ![self] = NullLock]
                                    /\ pc' = [pc EXCEPT ![self] = "Has_Work_Loop"]
                               ELSE /\ pc' = [pc EXCEPT ![self] = "IncrementLQAClocK2"]
                                    /\ UNCHANGED << LQLocks, HasWork >>
                         /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                         GQPPPointer, GQLock, LQA, LQAClock, 
                                         ClkCycles, LQASizes, LQB, LQBSizes, 
                                         TaskIdCurrent, TasksFinished, 
                                         RTStarted, RTStopped, Futures, 
                                         FuturePush, FuturesBlocked, 
                                         FutureWorkers, FDReadsAvailable, 
                                         FDWritesAvailable, KQueues, 
                                         TaskReadyAges, RoundRobinToken, tid_, 
                                         task, I_, J, K, L, kq_out, 
                                         current_time, lqbuf, wr, tid, I, 
                                         fildes_, Steps_, fildes, Steps, 
                                         PolledRead >>

IncrementLQAClocK2(self) == /\ pc[self] = "IncrementLQAClocK2"
                            /\ LQAClock' = [LQAClock EXCEPT ![self] = LQAClock[self] - 1]
                            /\ LQA' = [LQA EXCEPT ![self][LQAClock'[self]].state = TSRunning]
                            /\ task' = [task EXCEPT ![self] = LQA'[self][LQAClock'[self]]]
                            /\ HasWork' = [HasWork EXCEPT ![self] = TRUE]
                            /\ pc' = [pc EXCEPT ![self] = "LQ_Unlock2"]
                            /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                            GQBSize, GQPPPointer, GQLock, 
                                            ClkCycles, LQASizes, LQB, LQBSizes, 
                                            LQLocks, TaskIdCurrent, 
                                            TasksFinished, RTStarted, 
                                            RTStopped, Futures, FuturePush, 
                                            FuturesBlocked, FutureWorkers, 
                                            FDReadsAvailable, 
                                            FDWritesAvailable, KQueues, 
                                            TaskReadyAges, RoundRobinToken, 
                                            tid_, I_, J, K, L, kq_out, 
                                            current_time, lqbuf, wr, tid, I, 
                                            fildes_, Steps_, fildes, Steps, 
                                            PolledRead >>

LQ_Unlock2(self) == /\ pc[self] = "LQ_Unlock2"
                    /\ LQLocks' = [LQLocks EXCEPT ![self] = NullLock]
                    /\ pc' = [pc EXCEPT ![self] = "Has_Work_Loop"]
                    /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                    GQPPPointer, GQLock, LQA, LQAClock, 
                                    ClkCycles, LQASizes, LQB, LQBSizes, 
                                    TaskIdCurrent, TasksFinished, RTStarted, 
                                    RTStopped, Futures, FuturePush, 
                                    FuturesBlocked, FutureWorkers, 
                                    FDReadsAvailable, FDWritesAvailable, 
                                    KQueues, TaskReadyAges, RoundRobinToken, 
                                    tid_, task, HasWork, I_, J, K, L, kq_out, 
                                    current_time, lqbuf, wr, tid, I, fildes_, 
                                    Steps_, fildes, Steps, PolledRead >>

WFinish(self) == /\ pc[self] = "WFinish"
                 /\ TRUE
                 /\ pc' = [pc EXCEPT ![self] = "Done"]
                 /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                 GQPPPointer, GQLock, LQA, LQAClock, ClkCycles, 
                                 LQASizes, LQB, LQBSizes, LQLocks, 
                                 TaskIdCurrent, TasksFinished, RTStarted, 
                                 RTStopped, Futures, FuturePush, 
                                 FuturesBlocked, FutureWorkers, 
                                 FDReadsAvailable, FDWritesAvailable, KQueues, 
                                 TaskReadyAges, RoundRobinToken, tid_, task, 
                                 HasWork, I_, J, K, L, kq_out, current_time, 
                                 lqbuf, wr, tid, I, fildes_, Steps_, fildes, 
                                 Steps, PolledRead >>

WorkerThread(self) == WWait(self) \/ Main_Loop(self) \/ RTStopCheck(self)
                         \/ Kernel(self) \/ ProcessQB_LQ_Lock(self)
                         \/ LQ_Flush_Loop(self)
                         \/ LQ_Flush_Loop_Inner(self)
                         \/ LQ_Flush_Continue(self)
                         \/ LQ_Flush_Remove_From_Old(self)
                         \/ Flush_To_LQB_Continuation(self)
                         \/ LQ_Push_TO_KQ_Check_Create(self)
                         \/ LQ_Push_TO_KQ_Push(self)
                         \/ LQ_Push_TO_KQ_Push_Cont(self)
                         \/ LQ_Flush_To_GQB(self)
                         \/ LQ_Flush_To_GQBLoop1(self)
                         \/ LQ_Flush_To_GQBLoop1_Check_KQ(self)
                         \/ LQ_Flush_To_GQBLoop1_Add_To_KQ(self)
                         \/ LQ_Flush_To_GQB2(self)
                         \/ LQ_Flush_To_GQBLoop2(self)
                         \/ LQ_Flush_To_GQBLoop2AfterCheckContinuation(self)
                         \/ LQ_Flush_Step(self)
                         \/ LQ_GQ_CheckPushPull(self)
                         \/ Begin_LQ_GQ_PushPull(self)
                         \/ AttemptEnqueueFromGlobalLockGQ2(self)
                         \/ GQ_Poll_Check_KQ2(self)
                         \/ GQ_Poll_KQ_Begin2(self)
                         \/ GQ_Update_Ready2(self)
                         \/ GQ_Flush_Ready_Begin2(self)
                         \/ GQ_Flush_Ready2(self)
                         \/ GQ_Flush_Check_Timer2(self)
                         \/ GQ_Flush_Ready_Check_Ready2(self)
                         \/ GQ_Flush_Ready_Step2(self)
                         \/ GQ_Flush_Ready_Done2(self)
                         \/ AttemptEnqueueFromGlobalWhile2(self)
                         \/ UpdateGQAPointers2(self)
                         \/ UpdateGQAPointersCheck2(self)
                         \/ PushPullBegin(self)
                         \/ PerformFirstPushPull(self) \/ PushPull(self)
                         \/ PerformPushPull(self) \/ PushPullStep(self)
                         \/ AttemptEnqueueFromGlobalFinish2(self)
                         \/ LQ_Poll_KQ(self) \/ LQ_Poll_KQ_Begin(self)
                         \/ Update_Ready(self) \/ Flush_Ready_Begin(self)
                         \/ Flush_Ready(self) \/ Flush_Check_Timer(self)
                         \/ Flush_Ready_Check_Ready(self)
                         \/ CheckLQSize_(self) \/ LockGQ_(self)
                         \/ PushGQLoop_(self) \/ PushGQStatusCheck_(self)
                         \/ PushTaskNotNull_(self) \/ PushGQPushToKQ_(self)
                         \/ GQPushWhileStep_(self) \/ UnlockGQ_(self)
                         \/ CheckClock_(self) \/ PushLQ_(self)
                         \/ Flush_Ready_Check_Ready_Move_Old(self)
                         \/ Flush_Ready_Step(self)
                         \/ Flush_Ready_Done(self) \/ LQ_Reset_Clock(self)
                         \/ LQ_Pull(self) \/ LQ_Unlock(self)
                         \/ CheckHasWork(self)
                         \/ AttemptEnqueueFromGlobalLockLQ(self)
                         \/ AttemptEnqueueFromGlobalLockGQ(self)
                         \/ GQ_Poll_Check_KQ(self)
                         \/ GQ_Poll_KQ_Begin(self) \/ GQ_Update_Ready(self)
                         \/ GQ_Flush_Ready_Begin(self)
                         \/ GQ_Flush_Ready(self)
                         \/ GQ_Flush_Check_Timer(self)
                         \/ GQ_Flush_Ready_Check_Ready(self)
                         \/ GQ_Flush_Ready_Step(self)
                         \/ GQ_Flush_Ready_Done(self)
                         \/ AttemptEnqueueFromGlobalWhile(self)
                         \/ UpdateGQAPointers(self)
                         \/ UpdateGQAPointersCheck(self)
                         \/ AttemptEnqueueFromGlobalFinish(self)
                         \/ EnqueueFromGlobalCheck(self)
                         \/ WorkStealingBegin(self)
                         \/ WorkStealingMainLoop(self)
                         \/ WorkStealingFinishedStolen(self)
                         \/ WorkStealingLoopStep(self)
                         \/ WorkStealingAcquireSelfLock(self)
                         \/ WorkStealingAcquireVictimLock(self)
                         \/ WorkstealingCheck1(self)
                         \/ WorkStealingCont1(self)
                         \/ WorkstealingSteal(self)
                         \/ WorkStealingFinishedStolen1(self)
                         \/ WorkStealingAcquireVictimLock2(self)
                         \/ WorkstealingCheck2(self)
                         \/ WorkStealingCont2(self)
                         \/ WorkstealingSteal2(self)
                         \/ WorkStealingUnlockVictimLock2(self)
                         \/ No_Tasks(self) \/ Has_Work_Loop(self)
                         \/ DoFuturePoll(self) \/ ProcessStatus(self)
                         \/ ProcessStatusInLQ(self)
                         \/ LQ_Unlock_AfterProc(self) \/ LQ_Lock2(self)
                         \/ LQ_Pull2(self) \/ LQ_Pull_Empty2(self)
                         \/ UpdateLQAClock2(self)
                         \/ IncrementLQAClocK2(self) \/ LQ_Unlock2(self)
                         \/ WFinish(self)

TPPLoop(self) == /\ pc[self] = "TPPLoop"
                 /\ pc' = [pc EXCEPT ![self] = "TPPStart"]
                 /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                 GQPPPointer, GQLock, LQA, LQAClock, ClkCycles, 
                                 LQASizes, LQB, LQBSizes, LQLocks, 
                                 TaskIdCurrent, TasksFinished, RTStarted, 
                                 RTStopped, Futures, FuturePush, 
                                 FuturesBlocked, FutureWorkers, 
                                 FDReadsAvailable, FDWritesAvailable, KQueues, 
                                 TaskReadyAges, RoundRobinToken, tid_, task, 
                                 HasWork, I_, J, K, L, kq_out, current_time, 
                                 lqbuf, wr, tid, I, fildes_, Steps_, fildes, 
                                 Steps, PolledRead >>

TPPStart(self) == /\ pc[self] = "TPPStart"
                  /\ FuturePush[wr[self]] # NullFuture \/ RTStopped
                  /\ IF RTStopped
                        THEN /\ pc' = [pc EXCEPT ![self] = "TPPDone"]
                             /\ UNCHANGED << TaskIdCurrent, TaskReadyAges, tid >>
                        ELSE /\ TaskIdCurrent' = TaskIdCurrent + 1
                             /\ TaskReadyAges' = Append(TaskReadyAges, 0)
                             /\ tid' = [tid EXCEPT ![self] = TaskIdCurrent']
                             /\ pc' = [pc EXCEPT ![self] = "TPPLockLQ"]
                  /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                  GQPPPointer, GQLock, LQA, LQAClock, 
                                  ClkCycles, LQASizes, LQB, LQBSizes, LQLocks, 
                                  TasksFinished, RTStarted, RTStopped, Futures, 
                                  FuturePush, FuturesBlocked, FutureWorkers, 
                                  FDReadsAvailable, FDWritesAvailable, KQueues, 
                                  RoundRobinToken, tid_, task, HasWork, I_, J, 
                                  K, L, kq_out, current_time, lqbuf, wr, I, 
                                  fildes_, Steps_, fildes, Steps, PolledRead >>

TPPLockLQ(self) == /\ pc[self] = "TPPLockLQ"
                   /\ LQLocks[wr[self]] = NullLock
                   /\ LQLocks' = [LQLocks EXCEPT ![wr[self]] = wr[self]]
                   /\ pc' = [pc EXCEPT ![self] = "CheckLQSize"]
                   /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                   GQPPPointer, GQLock, LQA, LQAClock, 
                                   ClkCycles, LQASizes, LQB, LQBSizes, 
                                   TaskIdCurrent, TasksFinished, RTStarted, 
                                   RTStopped, Futures, FuturePush, 
                                   FuturesBlocked, FutureWorkers, 
                                   FDReadsAvailable, FDWritesAvailable, 
                                   KQueues, TaskReadyAges, RoundRobinToken, 
                                   tid_, task, HasWork, I_, J, K, L, kq_out, 
                                   current_time, lqbuf, wr, tid, I, fildes_, 
                                   Steps_, fildes, Steps, PolledRead >>

CheckLQSize(self) == /\ pc[self] = "CheckLQSize"
                     /\ IF LQASizes[wr[self]] = LQSize
                           THEN /\ pc' = [pc EXCEPT ![self] = "LockGQ"]
                           ELSE /\ pc' = [pc EXCEPT ![self] = "PushLQ"]
                     /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                     GQPPPointer, GQLock, LQA, LQAClock, 
                                     ClkCycles, LQASizes, LQB, LQBSizes, 
                                     LQLocks, TaskIdCurrent, TasksFinished, 
                                     RTStarted, RTStopped, Futures, FuturePush, 
                                     FuturesBlocked, FutureWorkers, 
                                     FDReadsAvailable, FDWritesAvailable, 
                                     KQueues, TaskReadyAges, RoundRobinToken, 
                                     tid_, task, HasWork, I_, J, K, L, kq_out, 
                                     current_time, lqbuf, wr, tid, I, fildes_, 
                                     Steps_, fildes, Steps, PolledRead >>

LockGQ(self) == /\ pc[self] = "LockGQ"
                /\ GQLock = NullLock
                /\ GQLock' = wr[self]
                /\ I' = [I EXCEPT ![self] = LQSize \div 2 + 1]
                /\ pc' = [pc EXCEPT ![self] = "PushGQLoop"]
                /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                GQPPPointer, LQA, LQAClock, ClkCycles, 
                                LQASizes, LQB, LQBSizes, LQLocks, 
                                TaskIdCurrent, TasksFinished, RTStarted, 
                                RTStopped, Futures, FuturePush, FuturesBlocked, 
                                FutureWorkers, FDReadsAvailable, 
                                FDWritesAvailable, KQueues, TaskReadyAges, 
                                RoundRobinToken, tid_, task, HasWork, I_, J, K, 
                                L, kq_out, current_time, lqbuf, wr, tid, 
                                fildes_, Steps_, fildes, Steps, PolledRead >>

PushGQLoop(self) == /\ pc[self] = "PushGQLoop"
                    /\ IF I[self] < LQSize
                          THEN /\ pc' = [pc EXCEPT ![self] = "PushGQStatusCheck"]
                          ELSE /\ pc' = [pc EXCEPT ![self] = "UnlockGQ"]
                    /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                    GQPPPointer, GQLock, LQA, LQAClock, 
                                    ClkCycles, LQASizes, LQB, LQBSizes, 
                                    LQLocks, TaskIdCurrent, TasksFinished, 
                                    RTStarted, RTStopped, Futures, FuturePush, 
                                    FuturesBlocked, FutureWorkers, 
                                    FDReadsAvailable, FDWritesAvailable, 
                                    KQueues, TaskReadyAges, RoundRobinToken, 
                                    tid_, task, HasWork, I_, J, K, L, kq_out, 
                                    current_time, lqbuf, wr, tid, I, fildes_, 
                                    Steps_, fildes, Steps, PolledRead >>

PushGQStatusCheck(self) == /\ pc[self] = "PushGQStatusCheck"
                           /\ IF LQA[wr[self]][I[self]] # NullTask
                                 THEN /\ pc' = [pc EXCEPT ![self] = "PushTaskNotNull"]
                                 ELSE /\ pc' = [pc EXCEPT ![self] = "GQPushWhileStep"]
                           /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                           GQBSize, GQPPPointer, GQLock, LQA, 
                                           LQAClock, ClkCycles, LQASizes, LQB, 
                                           LQBSizes, LQLocks, TaskIdCurrent, 
                                           TasksFinished, RTStarted, RTStopped, 
                                           Futures, FuturePush, FuturesBlocked, 
                                           FutureWorkers, FDReadsAvailable, 
                                           FDWritesAvailable, KQueues, 
                                           TaskReadyAges, RoundRobinToken, 
                                           tid_, task, HasWork, I_, J, K, L, 
                                           kq_out, current_time, lqbuf, wr, 
                                           tid, I, fildes_, Steps_, fildes, 
                                           Steps, PolledRead >>

PushTaskNotNull(self) == /\ pc[self] = "PushTaskNotNull"
                         /\ IF LQA[wr[self]][I[self]].state = TSReady
                               THEN /\ GQALast' = GQALast + 1
                                    /\ GQA' = [GQA EXCEPT ![((GQALast' - 1) % GQSize) + 1] = LQA[wr[self]][I[self]]]
                                    /\ LQA' = [LQA EXCEPT ![wr[self]][I[self]] = NullTask]
                                    /\ pc' = [pc EXCEPT ![self] = "GQPushWhileStep"]
                                    /\ UNCHANGED << GQB, GQBSize, KQueues >>
                               ELSE /\ IF LQA[wr[self]][I[self]].state \in {TSBTimer, TSBIO}
                                          THEN /\ GQBSize' = GQBSize + 1
                                               /\ GQB' = [GQB EXCEPT ![GQBSize'] = LQA[wr[self]][I[self]]]
                                               /\ LQA' = [LQA EXCEPT ![wr[self]][I[self]] = NullTask]
                                               /\ IF KQueues[0] = NullKQ
                                                     THEN /\ KQueues' = [KQueues EXCEPT ![0] = NewKQ]
                                                     ELSE /\ TRUE
                                                          /\ UNCHANGED KQueues
                                               /\ pc' = [pc EXCEPT ![self] = "PushGQPushToKQ"]
                                          ELSE /\ pc' = [pc EXCEPT ![self] = "GQPushWhileStep"]
                                               /\ UNCHANGED << GQB, GQBSize, 
                                                               LQA, KQueues >>
                                    /\ UNCHANGED << GQA, GQALast >>
                         /\ UNCHANGED << GQAFirst, GQPPPointer, GQLock, 
                                         LQAClock, ClkCycles, LQASizes, LQB, 
                                         LQBSizes, LQLocks, TaskIdCurrent, 
                                         TasksFinished, RTStarted, RTStopped, 
                                         Futures, FuturePush, FuturesBlocked, 
                                         FutureWorkers, FDReadsAvailable, 
                                         FDWritesAvailable, TaskReadyAges, 
                                         RoundRobinToken, tid_, task, HasWork, 
                                         I_, J, K, L, kq_out, current_time, 
                                         lqbuf, wr, tid, I, fildes_, Steps_, 
                                         fildes, Steps, PolledRead >>

PushGQPushToKQ(self) == /\ pc[self] = "PushGQPushToKQ"
                        /\ IF GQB[GQBSize].state = TSBIO
                              THEN /\ KQueues' = [KQueues EXCEPT ![0].waiting = Append (KQueues[0].waiting, [ fd |-> GQB[GQBSize].blocked_io_info.fd, kind |-> GQB[GQBSize].blocked_io_info.ty, data |-> 0, eof |-> FALSE, t_id |-> GQB[GQBSize].t_id ])]
                              ELSE /\ TRUE
                                   /\ UNCHANGED KQueues
                        /\ pc' = [pc EXCEPT ![self] = "GQPushWhileStep"]
                        /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                        GQPPPointer, GQLock, LQA, LQAClock, 
                                        ClkCycles, LQASizes, LQB, LQBSizes, 
                                        LQLocks, TaskIdCurrent, TasksFinished, 
                                        RTStarted, RTStopped, Futures, 
                                        FuturePush, FuturesBlocked, 
                                        FutureWorkers, FDReadsAvailable, 
                                        FDWritesAvailable, TaskReadyAges, 
                                        RoundRobinToken, tid_, task, HasWork, 
                                        I_, J, K, L, kq_out, current_time, 
                                        lqbuf, wr, tid, I, fildes_, Steps_, 
                                        fildes, Steps, PolledRead >>

GQPushWhileStep(self) == /\ pc[self] = "GQPushWhileStep"
                         /\ I' = [I EXCEPT ![self] = I[self] + 1]
                         /\ pc' = [pc EXCEPT ![self] = "PushGQLoop"]
                         /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                         GQPPPointer, GQLock, LQA, LQAClock, 
                                         ClkCycles, LQASizes, LQB, LQBSizes, 
                                         LQLocks, TaskIdCurrent, TasksFinished, 
                                         RTStarted, RTStopped, Futures, 
                                         FuturePush, FuturesBlocked, 
                                         FutureWorkers, FDReadsAvailable, 
                                         FDWritesAvailable, KQueues, 
                                         TaskReadyAges, RoundRobinToken, tid_, 
                                         task, HasWork, I_, J, K, L, kq_out, 
                                         current_time, lqbuf, wr, tid, fildes_, 
                                         Steps_, fildes, Steps, PolledRead >>

UnlockGQ(self) == /\ pc[self] = "UnlockGQ"
                  /\ GQLock' = NullLock
                  /\ LQASizes' = [LQASizes EXCEPT ![wr[self]] = LQSize \div 2]
                  /\ pc' = [pc EXCEPT ![self] = "CheckClock"]
                  /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                  GQPPPointer, LQA, LQAClock, ClkCycles, LQB, 
                                  LQBSizes, LQLocks, TaskIdCurrent, 
                                  TasksFinished, RTStarted, RTStopped, Futures, 
                                  FuturePush, FuturesBlocked, FutureWorkers, 
                                  FDReadsAvailable, FDWritesAvailable, KQueues, 
                                  TaskReadyAges, RoundRobinToken, tid_, task, 
                                  HasWork, I_, J, K, L, kq_out, current_time, 
                                  lqbuf, wr, tid, I, fildes_, Steps_, fildes, 
                                  Steps, PolledRead >>

CheckClock(self) == /\ pc[self] = "CheckClock"
                    /\ IF LQAClock[wr[self]] > LQASizes[wr[self]]
                          THEN /\ LQASizes' = [LQASizes EXCEPT ![wr[self]] = LQASizes[wr[self]] + 1]
                               /\ LQA' = [LQA EXCEPT ![wr[self]] = [LQA[wr[self]] EXCEPT ![LQASizes'[wr[self]]] = LQA[wr[self]][LQAClock[wr[self]]], ![LQAClock[wr[self]]] = NullTask]]
                               /\ LQAClock' = [LQAClock EXCEPT ![wr[self]] = LQASizes'[wr[self]]]
                          ELSE /\ TRUE
                               /\ UNCHANGED << LQA, LQAClock, LQASizes >>
                    /\ pc' = [pc EXCEPT ![self] = "PushLQ"]
                    /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                    GQPPPointer, GQLock, ClkCycles, LQB, 
                                    LQBSizes, LQLocks, TaskIdCurrent, 
                                    TasksFinished, RTStarted, RTStopped, 
                                    Futures, FuturePush, FuturesBlocked, 
                                    FutureWorkers, FDReadsAvailable, 
                                    FDWritesAvailable, KQueues, TaskReadyAges, 
                                    RoundRobinToken, tid_, task, HasWork, I_, 
                                    J, K, L, kq_out, current_time, lqbuf, wr, 
                                    tid, I, fildes_, Steps_, fildes, Steps, 
                                    PolledRead >>

PushLQ(self) == /\ pc[self] = "PushLQ"
                /\ LQASizes' = [LQASizes EXCEPT ![wr[self]] = LQASizes[wr[self]] + 1]
                /\ LQA' = [LQA EXCEPT ![wr[self]][LQASizes'[wr[self]]] = [t_id |-> tid[self], state |-> TSReady, future |-> FuturePush[wr[self]], blocked_io_info |-> NullBlockedIOInfoType]]
                /\ pc' = [pc EXCEPT ![self] = "TPPReleaseLockLQAndClearFuture"]
                /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                GQPPPointer, GQLock, LQAClock, ClkCycles, LQB, 
                                LQBSizes, LQLocks, TaskIdCurrent, 
                                TasksFinished, RTStarted, RTStopped, Futures, 
                                FuturePush, FuturesBlocked, FutureWorkers, 
                                FDReadsAvailable, FDWritesAvailable, KQueues, 
                                TaskReadyAges, RoundRobinToken, tid_, task, 
                                HasWork, I_, J, K, L, kq_out, current_time, 
                                lqbuf, wr, tid, I, fildes_, Steps_, fildes, 
                                Steps, PolledRead >>

TPPReleaseLockLQAndClearFuture(self) == /\ pc[self] = "TPPReleaseLockLQAndClearFuture"
                                        /\ LQLocks' = [LQLocks EXCEPT ![wr[self]] = NullLock]
                                        /\ FuturePush' = [FuturePush EXCEPT ![wr[self]] = NullFuture]
                                        /\ pc' = [pc EXCEPT ![self] = "TPPLoop"]
                                        /\ UNCHANGED << GQA, GQAFirst, GQALast, 
                                                        GQB, GQBSize, 
                                                        GQPPPointer, GQLock, 
                                                        LQA, LQAClock, 
                                                        ClkCycles, LQASizes, 
                                                        LQB, LQBSizes, 
                                                        TaskIdCurrent, 
                                                        TasksFinished, 
                                                        RTStarted, RTStopped, 
                                                        Futures, 
                                                        FuturesBlocked, 
                                                        FutureWorkers, 
                                                        FDReadsAvailable, 
                                                        FDWritesAvailable, 
                                                        KQueues, TaskReadyAges, 
                                                        RoundRobinToken, tid_, 
                                                        task, HasWork, I_, J, 
                                                        K, L, kq_out, 
                                                        current_time, lqbuf, 
                                                        wr, tid, I, fildes_, 
                                                        Steps_, fildes, Steps, 
                                                        PolledRead >>

TPPDone(self) == /\ pc[self] = "TPPDone"
                 /\ TRUE
                 /\ pc' = [pc EXCEPT ![self] = "Done"]
                 /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                 GQPPPointer, GQLock, LQA, LQAClock, ClkCycles, 
                                 LQASizes, LQB, LQBSizes, LQLocks, 
                                 TaskIdCurrent, TasksFinished, RTStarted, 
                                 RTStopped, Futures, FuturePush, 
                                 FuturesBlocked, FutureWorkers, 
                                 FDReadsAvailable, FDWritesAvailable, KQueues, 
                                 TaskReadyAges, RoundRobinToken, tid_, task, 
                                 HasWork, I_, J, K, L, kq_out, current_time, 
                                 lqbuf, wr, tid, I, fildes_, Steps_, fildes, 
                                 Steps, PolledRead >>

TaskPusherProcess(self) == TPPLoop(self) \/ TPPStart(self)
                              \/ TPPLockLQ(self) \/ CheckLQSize(self)
                              \/ LockGQ(self) \/ PushGQLoop(self)
                              \/ PushGQStatusCheck(self)
                              \/ PushTaskNotNull(self)
                              \/ PushGQPushToKQ(self)
                              \/ GQPushWhileStep(self) \/ UnlockGQ(self)
                              \/ CheckClock(self) \/ PushLQ(self)
                              \/ TPPReleaseLockLQAndClearFuture(self)
                              \/ TPPDone(self)

RootFutureAwaitStarted(self) == /\ pc[self] = "RootFutureAwaitStarted"
                                /\ Futures[self] = FSPolling \/ RTStopped = TRUE
                                /\ IF RTStopped = TRUE
                                      THEN /\ pc' = [pc EXCEPT ![self] = "RootFutureDone"]
                                      ELSE /\ pc' = [pc EXCEPT ![self] = "RootFutureStarted"]
                                /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                                GQBSize, GQPPPointer, GQLock, 
                                                LQA, LQAClock, ClkCycles, 
                                                LQASizes, LQB, LQBSizes, 
                                                LQLocks, TaskIdCurrent, 
                                                TasksFinished, RTStarted, 
                                                RTStopped, Futures, FuturePush, 
                                                FuturesBlocked, FutureWorkers, 
                                                FDReadsAvailable, 
                                                FDWritesAvailable, KQueues, 
                                                TaskReadyAges, RoundRobinToken, 
                                                tid_, task, HasWork, I_, J, K, 
                                                L, kq_out, current_time, lqbuf, 
                                                wr, tid, I, fildes_, Steps_, 
                                                fildes, Steps, PolledRead >>

RootFutureStarted(self) == /\ pc[self] = "RootFutureStarted"
                           /\ IF Steps_[self] < NumFutures - 1
                                 THEN /\ Steps_' = [Steps_ EXCEPT ![self] = Steps_[self] + 1]
                                      /\ pc' = [pc EXCEPT ![self] = "SpawnFuture"]
                                 ELSE /\ pc' = [pc EXCEPT ![self] = "RootFutureDone"]
                                      /\ UNCHANGED Steps_
                           /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                           GQBSize, GQPPPointer, GQLock, LQA, 
                                           LQAClock, ClkCycles, LQASizes, LQB, 
                                           LQBSizes, LQLocks, TaskIdCurrent, 
                                           TasksFinished, RTStarted, RTStopped, 
                                           Futures, FuturePush, FuturesBlocked, 
                                           FutureWorkers, FDReadsAvailable, 
                                           FDWritesAvailable, KQueues, 
                                           TaskReadyAges, RoundRobinToken, 
                                           tid_, task, HasWork, I_, J, K, L, 
                                           kq_out, current_time, lqbuf, wr, 
                                           tid, I, fildes_, fildes, Steps, 
                                           PolledRead >>

SpawnFuture(self) == /\ pc[self] = "SpawnFuture"
                     /\ FuturePush[FutureWorkers[self]] = NullFuture
                     /\ FuturePush' = [FuturePush EXCEPT ![FutureWorkers[self]] = RootFuture + Steps_[self]]
                     /\ pc' = [pc EXCEPT ![self] = "SpawnFutureWaitFinish"]
                     /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                     GQPPPointer, GQLock, LQA, LQAClock, 
                                     ClkCycles, LQASizes, LQB, LQBSizes, 
                                     LQLocks, TaskIdCurrent, TasksFinished, 
                                     RTStarted, RTStopped, Futures, 
                                     FuturesBlocked, FutureWorkers, 
                                     FDReadsAvailable, FDWritesAvailable, 
                                     KQueues, TaskReadyAges, RoundRobinToken, 
                                     tid_, task, HasWork, I_, J, K, L, kq_out, 
                                     current_time, lqbuf, wr, tid, I, fildes_, 
                                     Steps_, fildes, Steps, PolledRead >>

SpawnFutureWaitFinish(self) == /\ pc[self] = "SpawnFutureWaitFinish"
                               /\ FuturePush[FutureWorkers[self]] = NullFuture
                               /\ pc' = [pc EXCEPT ![self] = "RootFutureStarted"]
                               /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                               GQBSize, GQPPPointer, GQLock, 
                                               LQA, LQAClock, ClkCycles, 
                                               LQASizes, LQB, LQBSizes, 
                                               LQLocks, TaskIdCurrent, 
                                               TasksFinished, RTStarted, 
                                               RTStopped, Futures, FuturePush, 
                                               FuturesBlocked, FutureWorkers, 
                                               FDReadsAvailable, 
                                               FDWritesAvailable, KQueues, 
                                               TaskReadyAges, RoundRobinToken, 
                                               tid_, task, HasWork, I_, J, K, 
                                               L, kq_out, current_time, lqbuf, 
                                               wr, tid, I, fildes_, Steps_, 
                                               fildes, Steps, PolledRead >>

RootFutureDone(self) == /\ pc[self] = "RootFutureDone"
                        /\ Futures' = [Futures EXCEPT ![self] = FSCompleted]
                        /\ pc' = [pc EXCEPT ![self] = "Done"]
                        /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                        GQPPPointer, GQLock, LQA, LQAClock, 
                                        ClkCycles, LQASizes, LQB, LQBSizes, 
                                        LQLocks, TaskIdCurrent, TasksFinished, 
                                        RTStarted, RTStopped, FuturePush, 
                                        FuturesBlocked, FutureWorkers, 
                                        FDReadsAvailable, FDWritesAvailable, 
                                        KQueues, TaskReadyAges, 
                                        RoundRobinToken, tid_, task, HasWork, 
                                        I_, J, K, L, kq_out, current_time, 
                                        lqbuf, wr, tid, I, fildes_, Steps_, 
                                        fildes, Steps, PolledRead >>

RF(self) == RootFutureAwaitStarted(self) \/ RootFutureStarted(self)
               \/ SpawnFuture(self) \/ SpawnFutureWaitFinish(self)
               \/ RootFutureDone(self)

OtherFutureStarted(self) == /\ pc[self] = "OtherFutureStarted"
                            /\ IF Steps[self] < NumFutureSteps
                                  THEN /\ pc' = [pc EXCEPT ![self] = "AwaitInLoop"]
                                  ELSE /\ pc' = [pc EXCEPT ![self] = "OtherFutureDone"]
                            /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                            GQBSize, GQPPPointer, GQLock, LQA, 
                                            LQAClock, ClkCycles, LQASizes, LQB, 
                                            LQBSizes, LQLocks, TaskIdCurrent, 
                                            TasksFinished, RTStarted, 
                                            RTStopped, Futures, FuturePush, 
                                            FuturesBlocked, FutureWorkers, 
                                            FDReadsAvailable, 
                                            FDWritesAvailable, KQueues, 
                                            TaskReadyAges, RoundRobinToken, 
                                            tid_, task, HasWork, I_, J, K, L, 
                                            kq_out, current_time, lqbuf, wr, 
                                            tid, I, fildes_, Steps_, fildes, 
                                            Steps, PolledRead >>

AwaitInLoop(self) == /\ pc[self] = "AwaitInLoop"
                     /\ Futures[self] = FSPolling \/ RTStopped = TRUE
                     /\ IF RTStopped = TRUE
                           THEN /\ pc' = [pc EXCEPT ![self] = "OtherFutureDone"]
                           ELSE /\ pc' = [pc EXCEPT ![self] = "OtherFutureContinue"]
                     /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                     GQPPPointer, GQLock, LQA, LQAClock, 
                                     ClkCycles, LQASizes, LQB, LQBSizes, 
                                     LQLocks, TaskIdCurrent, TasksFinished, 
                                     RTStarted, RTStopped, Futures, FuturePush, 
                                     FuturesBlocked, FutureWorkers, 
                                     FDReadsAvailable, FDWritesAvailable, 
                                     KQueues, TaskReadyAges, RoundRobinToken, 
                                     tid_, task, HasWork, I_, J, K, L, kq_out, 
                                     current_time, lqbuf, wr, tid, I, fildes_, 
                                     Steps_, fildes, Steps, PolledRead >>

OtherFutureContinue(self) == /\ pc[self] = "OtherFutureContinue"
                             /\ Steps' = [Steps EXCEPT ![self] = Steps[self] + 1]
                             /\ \/ /\ FuturesBlocked' = [FuturesBlocked EXCEPT ![self] = [kind |-> FBKindRead, fd |-> fildes[self]]]
                                   /\ PolledRead' = [PolledRead EXCEPT ![self] = TRUE]
                                   /\ Futures' = [Futures EXCEPT ![self] = FSReturned]
                                   /\ pc' = [pc EXCEPT ![self] = "Cont1"]
                                   /\ UNCHANGED FDReadsAvailable
                                \/ /\ FuturesBlocked' = [FuturesBlocked EXCEPT ![self] = [kind |-> FBKindWrite, fd |-> fildes[self]]]
                                   /\ Futures' = [Futures EXCEPT ![self] = FSReturned]
                                   /\ pc' = [pc EXCEPT ![self] = "Cont2"]
                                   /\ UNCHANGED <<FDReadsAvailable, PolledRead>>
                                \/ /\ FuturesBlocked' = [FuturesBlocked EXCEPT ![self] = [kind |-> FBKindTimer, fd |-> NullFD]]
                                   /\ Futures' = [Futures EXCEPT ![self] = FSReturned]
                                   /\ pc' = [pc EXCEPT ![self] = "Cont3"]
                                   /\ UNCHANGED <<FDReadsAvailable, PolledRead>>
                                \/ /\ IF PolledRead[self] = TRUE
                                         THEN /\ FDReadsAvailable' = [FDReadsAvailable EXCEPT ![fildes[self]] = FDReadsAvailable[fildes[self]] - 16]
                                              /\ PolledRead' = [PolledRead EXCEPT ![self] = FALSE]
                                         ELSE /\ TRUE
                                              /\ UNCHANGED << FDReadsAvailable, 
                                                              PolledRead >>
                                   /\ Futures' = [Futures EXCEPT ![self] = FSReturned]
                                   /\ pc' = [pc EXCEPT ![self] = "Cont4"]
                                   /\ UNCHANGED FuturesBlocked
                                \/ /\ Futures' = [Futures EXCEPT ![self] = FSReturned]
                                   /\ pc' = [pc EXCEPT ![self] = "Cont5"]
                                   /\ UNCHANGED <<FuturesBlocked, FDReadsAvailable, PolledRead>>
                                \/ /\ pc' = [pc EXCEPT ![self] = "OtherFutureDone"]
                                   /\ UNCHANGED <<Futures, FuturesBlocked, FDReadsAvailable, PolledRead>>
                             /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                             GQBSize, GQPPPointer, GQLock, LQA, 
                                             LQAClock, ClkCycles, LQASizes, 
                                             LQB, LQBSizes, LQLocks, 
                                             TaskIdCurrent, TasksFinished, 
                                             RTStarted, RTStopped, FuturePush, 
                                             FutureWorkers, FDWritesAvailable, 
                                             KQueues, TaskReadyAges, 
                                             RoundRobinToken, tid_, task, 
                                             HasWork, I_, J, K, L, kq_out, 
                                             current_time, lqbuf, wr, tid, I, 
                                             fildes_, Steps_, fildes >>

Cont1(self) == /\ pc[self] = "Cont1"
               /\ Futures[self] = FSPolling
               /\ pc' = [pc EXCEPT ![self] = "OtherFutureStarted"]
               /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                               GQPPPointer, GQLock, LQA, LQAClock, ClkCycles, 
                               LQASizes, LQB, LQBSizes, LQLocks, TaskIdCurrent, 
                               TasksFinished, RTStarted, RTStopped, Futures, 
                               FuturePush, FuturesBlocked, FutureWorkers, 
                               FDReadsAvailable, FDWritesAvailable, KQueues, 
                               TaskReadyAges, RoundRobinToken, tid_, task, 
                               HasWork, I_, J, K, L, kq_out, current_time, 
                               lqbuf, wr, tid, I, fildes_, Steps_, fildes, 
                               Steps, PolledRead >>

Cont2(self) == /\ pc[self] = "Cont2"
               /\ Futures[self] = FSPolling
               /\ pc' = [pc EXCEPT ![self] = "OtherFutureStarted"]
               /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                               GQPPPointer, GQLock, LQA, LQAClock, ClkCycles, 
                               LQASizes, LQB, LQBSizes, LQLocks, TaskIdCurrent, 
                               TasksFinished, RTStarted, RTStopped, Futures, 
                               FuturePush, FuturesBlocked, FutureWorkers, 
                               FDReadsAvailable, FDWritesAvailable, KQueues, 
                               TaskReadyAges, RoundRobinToken, tid_, task, 
                               HasWork, I_, J, K, L, kq_out, current_time, 
                               lqbuf, wr, tid, I, fildes_, Steps_, fildes, 
                               Steps, PolledRead >>

Cont3(self) == /\ pc[self] = "Cont3"
               /\ Futures[self] = FSPolling
               /\ pc' = [pc EXCEPT ![self] = "OtherFutureStarted"]
               /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                               GQPPPointer, GQLock, LQA, LQAClock, ClkCycles, 
                               LQASizes, LQB, LQBSizes, LQLocks, TaskIdCurrent, 
                               TasksFinished, RTStarted, RTStopped, Futures, 
                               FuturePush, FuturesBlocked, FutureWorkers, 
                               FDReadsAvailable, FDWritesAvailable, KQueues, 
                               TaskReadyAges, RoundRobinToken, tid_, task, 
                               HasWork, I_, J, K, L, kq_out, current_time, 
                               lqbuf, wr, tid, I, fildes_, Steps_, fildes, 
                               Steps, PolledRead >>

Cont4(self) == /\ pc[self] = "Cont4"
               /\ Futures[self] = FSPolling
               /\ pc' = [pc EXCEPT ![self] = "OtherFutureStarted"]
               /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                               GQPPPointer, GQLock, LQA, LQAClock, ClkCycles, 
                               LQASizes, LQB, LQBSizes, LQLocks, TaskIdCurrent, 
                               TasksFinished, RTStarted, RTStopped, Futures, 
                               FuturePush, FuturesBlocked, FutureWorkers, 
                               FDReadsAvailable, FDWritesAvailable, KQueues, 
                               TaskReadyAges, RoundRobinToken, tid_, task, 
                               HasWork, I_, J, K, L, kq_out, current_time, 
                               lqbuf, wr, tid, I, fildes_, Steps_, fildes, 
                               Steps, PolledRead >>

Cont5(self) == /\ pc[self] = "Cont5"
               /\ Futures[self] = FSPolling
               /\ pc' = [pc EXCEPT ![self] = "OtherFutureStarted"]
               /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                               GQPPPointer, GQLock, LQA, LQAClock, ClkCycles, 
                               LQASizes, LQB, LQBSizes, LQLocks, TaskIdCurrent, 
                               TasksFinished, RTStarted, RTStopped, Futures, 
                               FuturePush, FuturesBlocked, FutureWorkers, 
                               FDReadsAvailable, FDWritesAvailable, KQueues, 
                               TaskReadyAges, RoundRobinToken, tid_, task, 
                               HasWork, I_, J, K, L, kq_out, current_time, 
                               lqbuf, wr, tid, I, fildes_, Steps_, fildes, 
                               Steps, PolledRead >>

OtherFutureDone(self) == /\ pc[self] = "OtherFutureDone"
                         /\ Futures' = [Futures EXCEPT ![self] = FSCompleted]
                         /\ pc' = [pc EXCEPT ![self] = "Done"]
                         /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                         GQPPPointer, GQLock, LQA, LQAClock, 
                                         ClkCycles, LQASizes, LQB, LQBSizes, 
                                         LQLocks, TaskIdCurrent, TasksFinished, 
                                         RTStarted, RTStopped, FuturePush, 
                                         FuturesBlocked, FutureWorkers, 
                                         FDReadsAvailable, FDWritesAvailable, 
                                         KQueues, TaskReadyAges, 
                                         RoundRobinToken, tid_, task, HasWork, 
                                         I_, J, K, L, kq_out, current_time, 
                                         lqbuf, wr, tid, I, fildes_, Steps_, 
                                         fildes, Steps, PolledRead >>

OtherF(self) == OtherFutureStarted(self) \/ AwaitInLoop(self)
                   \/ OtherFutureContinue(self) \/ Cont1(self)
                   \/ Cont2(self) \/ Cont3(self) \/ Cont4(self)
                   \/ Cont5(self) \/ OtherFutureDone(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == RTSpawn
           \/ (\E self \in Workers: WorkerThread(self))
           \/ (\E self \in TaskPusherProcesses: TaskPusherProcess(self))
           \/ (\E self \in {RootFuture}: RF(self))
           \/ (\E self \in OtherFutures: OtherF(self))
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ SF_vars(RTSpawn)
        /\ \A self \in Workers : SF_vars(WorkerThread(self))
        /\ \A self \in TaskPusherProcesses : SF_vars(TaskPusherProcess(self))
        /\ \A self \in {RootFuture} : SF_vars(RF(self))
        /\ \A self \in OtherFutures : SF_vars(OtherF(self))

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 

=============================================================================
\* Modification History
\* Last modified Sat Jun 21 14:48:22 CEST 2025 by dinu
\* Created Sat May 24 12:56:52 CEST 2025 by dinu
