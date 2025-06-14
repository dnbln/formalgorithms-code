----------------------------- MODULE scheduler -----------------------------
EXTENDS Naturals, Integers, TLC, Sequences

CONSTANT GQSize
CONSTANT LQSize
CONSTANT NumWorkers
CONSTANT NumConnections
CONSTANT NullTask
CONSTANT NullLock
CONSTANT NullFuture

ASSUME GQSize >= 1
ASSUME LQSize >= 1
ASSUME NumWorkers >= 1
ASSUME NumConnections > 1

GQ == 1..GQSize
LQ == 1..LQSize
Workers == 1..NumWorkers

ASSUME NullLock \notin Workers

Task_Id == Nat

TaskPusherProcesses == NumWorkers + 1 .. NumWorkers * 2

TcpListenerFutureId == NumWorkers * 2 + 1
TcpSocketFutureId == TcpListenerFutureId + 1..TcpListenerFutureId + NumConnections
AllFutures == TcpListenerFutureId..TcpListenerFutureId + NumConnections

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

Task == [ t_id : Task_Id, state : TaskState, future : AllFutures ]
ASSUME NullTask \notin Task  
OptTask == Task \union {NullTask}

LQLocalType == [LQ -> OptTask]
LQGlobalType == [Workers -> LQLocalType]
LQSizesType == [Workers -> 0..LQSize]

LQLockType == Workers \union {NullLock}
LQLocksType == [Workers -> LQLockType]

GQType == [GQ -> OptTask]
GQLockType == Workers \union {NullLock}

(* --algorithm scheduler

variables
    \** Global queue
    GQA = [p \in GQ |-> NullTask]; \* Global active queue
    GQAFirst = 0; \* Global active queue first
    GQALast = 0; \* Global active queue last
    GQB = [p \in GQ |-> NullTask]; \* Global blocked queue
    GQBSize = 0; \* Global blocked queue size
    
    GQLock = NullLock;
    
    \** Local queues
    LQA = [w \in Workers |-> [p \in LQ |-> NullTask]]; \* Local active queues
    LQAClock = [w \in Workers |-> 0]; \* Local active queue clock indexes
    LQASizes = [w \in Workers |-> 0]; \* Local active queue sizes
    LQB = [w \in Workers |-> [p \in LQ |-> NullTask]]; \* Local blocked queues
    LQBSizes = [w \in Workers |-> 0]; \* Local blocked queue sizes
    
    LQLocks = [w \in Workers |-> NullLock];
    
    \** Task id generator
    TaskIdCurrent = 0; \* Task id generator current
    TasksFinished = 0; \* Task id generator number of tasks finished
    
    RTStarted = FALSE; \* set to TRUE when the runtime initialized and the worker threads can start
    RTStopped = FALSE; \* set to TRUE when all tasks are done, according to TasksFinished 
    Futures = [f \in AllFutures |-> FSNew]; \* Futures, for synchronization
    FuturePush = [w \in Workers |-> NullFuture];

define
    AllTasksDone == RTStarted = TRUE /\ TaskIdCurrent = TasksFinished
    AllWorkersFinished == 
        /\ \A t \in Workers: pc[t] = "Done"
        /\ \A t \in TaskPusherProcesses: pc[t] = "Done"
    WorkersStopOnceRTFlags == RTStopped => <>AllWorkersFinished
    RTStopFlaggedOnceAllTasksDone == AllTasksDone => <>RTStopped
    Correct ==
        /\ WorkersStopOnceRTFlags
        /\ RTStopFlaggedOnceAllTasksDone
    TypeInvariant ==
        /\ GQA \in GQType
        /\ GQB \in GQType
        /\ GQLock \in GQLockType
        /\ LQA \in LQGlobalType
        /\ LQAClock \in LQSizesType
        /\ LQASizes \in LQSizesType
        /\ LQB \in LQGlobalType
        /\ LQBSizes \in LQSizesType
        /\ LQLocks \in LQLocksType
        /\ RTStarted \in BOOLEAN
        /\ RTStopped \in BOOLEAN
        /\ Futures \in FuturesListType
        /\ FuturePush \in FuturePushType
end define;

macro Next_TId(var) begin
    TaskIdCurrent := TaskIdCurrent + 1;
    var := TaskIdCurrent + 1;
end macro;

fair+ process RTSpawn = 0
variables
    tid = 0;
begin
    RTGetNext:
        Next_TId(tid);
    RTSpawnInit:
        \* No need to lock here, workers await RTStarted which we only set on the next step.
        LQA[1][1] := [ t_id |-> tid, state |-> TSReady, future |-> TcpListenerFutureId ];
        LQASizes[1] := 1;
    RTStart:
        RTStarted := TRUE;
    RTLoopCheck:
        while (TaskIdCurrent # TasksFinished) do
            skip;
        end while;
    RTFinish:
        RTStopped := TRUE;
end process;

fair+ process WorkerThread \in Workers
variables
    task = NullTask;
    HasWork = FALSE;
    I = 1;
    K = 1;
begin
    WWait:
        await RTStarted = TRUE;
        
    Main_Loop:
        while TRUE do
            \* stop condition if coming from main scheduler thread
            RTStopCheck:
                if RTStopped = TRUE then
                    goto WFinish;
                end if;
            \* process qb
            ProcessQB_LQ_Lock:
                await LQLocks[self] = NullLock;
                LQLocks[self] := self;
                
            \* fetch next task (opt)
            LQ_Pull:
                if LQASizes[self] = 0 then
                    HasWork := FALSE;
                else
                    LQAClock[self] := LQAClock[self] + 1;
                    LQA[self][LQAClock[self]].state := TSRunning;
                    task := LQA[self][LQAClock[self]];
                    HasWork := TRUE;
                end if;
            LQ_Unlock:
                LQLocks[self] := NullLock;
            CheckHasWork:
                if HasWork = FALSE then
                    \* enqueue from other queues
                    skip;
                else
                    Has_Work_Loop:
                        while HasWork = TRUE do
                            DoFuturePoll:
                                \* Poll future
                                Futures[task.future] := FSPolling;
                            ProcessStatus:
                                await Futures[task.future] # FSPolling;
                                if Futures[task.future] = FSReturned then
                                    LQA[self][LQAClock[self]].state := TSReady;
                                else
                                    LQA[self][LQAClock[self]] := NullTask;
                                    TasksFinished := TasksFinished + 1;
                                end if;
                            LQ_Lock2:
                                await LQLocks[self] = NullLock;
                                LQLocks[self] := self;
                            LQ_Pull2:
                                if LQASizes[self] = 0 then
                                    LQ_Pull_Empty2:
                                        HasWork := FALSE;
                                else
                                    UpdateLQAClock2:
                                        if LQAClock[self] = LQASizes[self] then
                                            HasWork := FALSE;
                                            LQLocks[self] := NullLock; \* unlock
                                            goto Has_Work_Loop; \* exit
                                        end if;
                                    IncrementLQAClocK2:
                                        LQAClock[self] := LQAClock[self] + 1;
                                        LQA[self][LQAClock[self]].state := TSRunning;
                                        task := LQA[self][LQAClock[self]];
                                        HasWork := TRUE;
                                end if;
                            LQ_Unlock2:
                                LQLocks[self] := NullLock;
                        end while;
                end if;
            FlushBlocked:
                \* Flush blocked tasks to LQB, keep only alive tasks in LQA
                skip;
                LQ_Lock3:
                    await LQLocks[self] = NullLock;
                    LQLocks[self] := self;
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
                            LQA[self][K + 1] := LQA[self][I];
                        else
                            if LQA[self][I].state \in {TSBTimer, TSBIO} then
                                LQB[self][LQBSizes[self]] := LQA[self][I];
                                \* TODO: push to kqueue
                            end if;
                        end if;
                    LQ_Flush_Step:
                        I := I + 1;
                    end while;
                    LQASizes[self] := K;
                LQ_Reset_Clock:
                    LQAClock[self] := 0;
                LQ_Unlock3:
                    LQLocks[self] := NullLock;
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
            TPPCheckLQSize:
                if LQASizes[wr] = LQSize then
                    TPPLockGQ:
                        await GQLock = NullLock;
                        GQLock := wr;
                    TPPPushGQLoop:
                        while I < LQSize \div 2 do
                        TPPPushGQStatusCheck:
                            if LQA[wr][I] # NullTask then
                            TPPPushTaskNotNull:
                                if LQA[wr][I].state = TSReady then
                                    GQALast := GQALast + 1;
                                    GQA[(GQALast % GQSize) + 1] := LQA[wr][I];
                                    LQA[wr][I] := NullTask;
                                else
                                    if LQA[wr][I].state \in {TSBTimer, TSBIO} then
                                        GQBSize := GQBSize + 1;
                                        GQB[GQBSize] := LQA[wr][I];
                                        LQA[wr][I] := NullTask;
                                        \* TODO: add to kqueue
                                    end if;
                                end if;
                            end if;
                        TPPGQPushWhileStep:
                            I := I + 1;
                        end while;
                    TPPUnlockGQ:
                        GQLock := NullLock;
                end if;
            TPPPushLQ:
                LQASizes[wr] := LQASizes[wr] + 1;
                LQA[wr][LQASizes[wr]] := [t_id |-> tid, state |-> TSReady, future |-> FuturePush[wr]]; 
            TPPReleaseLockLQAndClearFuture:
                LQLocks[wr] := NullLock;
                FuturePush[wr] := NullFuture;
        end while;
    TPPDone:
        skip;
end process;


\*** End of scheduler

\*** From here on, we describe the client code, e.g. the code that interacts with the scheduler.

\*** Our root future (TCPListenerFuture) listens for connections, accepts them, and spawns socket handler futures (TCPSocketFuture)
\*** We model Polling futures through explicit synchronization of these processes

\*** These proesses are fair because any errors they might throw are catched by the worker threads, around the `.Poll` call
fair+ process TCPListenerFuture \in {TcpListenerFutureId}
variables
    ListenerSocketFd = 0;
begin
    ListenerFutureStarted:
        await Futures[self] = FSPolling;
        ListenerSocketFd := 1;
    ListenerFutureSocketCreatedReturn:
        Futures[self] := FSCompleted;
end process;

\*fair+ process TCPSocketFuture \in TcpSocketFutureId
\*variables
\*    SocketFd = 0;
\*begin
\*    SocketFutureStarted:
\*        await Futures[self] = FSPolling;
\*        SocketFd := 1;
\*    SocketFutureSocketCreatedReturn:
\*        Futures[self] := FSCompleted;
\*end process;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "77d8d6e7" /\ chksum(tla) = "78155665")
\* Process variable tid of process RTSpawn at line 129 col 5 changed to tid_
\* Process variable I of process WorkerThread at line 151 col 5 changed to I_
VARIABLES pc, GQA, GQAFirst, GQALast, GQB, GQBSize, GQLock, LQA, LQAClock, 
          LQASizes, LQB, LQBSizes, LQLocks, TaskIdCurrent, TasksFinished, 
          RTStarted, RTStopped, Futures, FuturePush

(* define statement *)
AllTasksDone == RTStarted = TRUE /\ TaskIdCurrent = TasksFinished
AllWorkersFinished ==
    /\ \A t \in Workers: pc[t] = "Done"
    /\ \A t \in TaskPusherProcesses: pc[t] = "Done"
WorkersStopOnceRTFlags == RTStopped => <>AllWorkersFinished
RTStopFlaggedOnceAllTasksDone == AllTasksDone => <>RTStopped
Correct ==
    /\ WorkersStopOnceRTFlags
    /\ RTStopFlaggedOnceAllTasksDone
TypeInvariant ==
    /\ GQA \in GQType
    /\ GQB \in GQType
    /\ GQLock \in GQLockType
    /\ LQA \in LQGlobalType
    /\ LQAClock \in LQSizesType
    /\ LQASizes \in LQSizesType
    /\ LQB \in LQGlobalType
    /\ LQBSizes \in LQSizesType
    /\ LQLocks \in LQLocksType
    /\ RTStarted \in BOOLEAN
    /\ RTStopped \in BOOLEAN
    /\ Futures \in FuturesListType
    /\ FuturePush \in FuturePushType

VARIABLES tid_, task, HasWork, I_, K, wr, tid, I, ListenerSocketFd

vars == << pc, GQA, GQAFirst, GQALast, GQB, GQBSize, GQLock, LQA, LQAClock, 
           LQASizes, LQB, LQBSizes, LQLocks, TaskIdCurrent, TasksFinished, 
           RTStarted, RTStopped, Futures, FuturePush, tid_, task, HasWork, I_, 
           K, wr, tid, I, ListenerSocketFd >>

ProcSet == {0} \cup (Workers) \cup (TaskPusherProcesses) \cup ({TcpListenerFutureId})

Init == (* Global variables *)
        /\ GQA = [p \in GQ |-> NullTask]
        /\ GQAFirst = 0
        /\ GQALast = 0
        /\ GQB = [p \in GQ |-> NullTask]
        /\ GQBSize = 0
        /\ GQLock = NullLock
        /\ LQA = [w \in Workers |-> [p \in LQ |-> NullTask]]
        /\ LQAClock = [w \in Workers |-> 0]
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
        (* Process RTSpawn *)
        /\ tid_ = 0
        (* Process WorkerThread *)
        /\ task = [self \in Workers |-> NullTask]
        /\ HasWork = [self \in Workers |-> FALSE]
        /\ I_ = [self \in Workers |-> 1]
        /\ K = [self \in Workers |-> 1]
        (* Process TaskPusherProcess *)
        /\ wr = [self \in TaskPusherProcesses |-> self - NumWorkers]
        /\ tid = [self \in TaskPusherProcesses |-> 0]
        /\ I = [self \in TaskPusherProcesses |-> 1]
        (* Process TCPListenerFuture *)
        /\ ListenerSocketFd = [self \in {TcpListenerFutureId} |-> 0]
        /\ pc = [self \in ProcSet |-> CASE self = 0 -> "RTGetNext"
                                        [] self \in Workers -> "WWait"
                                        [] self \in TaskPusherProcesses -> "TPPLoop"
                                        [] self \in {TcpListenerFutureId} -> "ListenerFutureStarted"]

RTGetNext == /\ pc[0] = "RTGetNext"
             /\ TaskIdCurrent' = TaskIdCurrent + 1
             /\ tid_' = TaskIdCurrent' + 1
             /\ pc' = [pc EXCEPT ![0] = "RTSpawnInit"]
             /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, GQLock, LQA, 
                             LQAClock, LQASizes, LQB, LQBSizes, LQLocks, 
                             TasksFinished, RTStarted, RTStopped, Futures, 
                             FuturePush, task, HasWork, I_, K, wr, tid, I, 
                             ListenerSocketFd >>

RTSpawnInit == /\ pc[0] = "RTSpawnInit"
               /\ LQA' = [LQA EXCEPT ![1][1] = [ t_id |-> tid_, state |-> TSReady, future |-> TcpListenerFutureId ]]
               /\ LQASizes' = [LQASizes EXCEPT ![1] = 1]
               /\ pc' = [pc EXCEPT ![0] = "RTStart"]
               /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, GQLock, 
                               LQAClock, LQB, LQBSizes, LQLocks, TaskIdCurrent, 
                               TasksFinished, RTStarted, RTStopped, Futures, 
                               FuturePush, tid_, task, HasWork, I_, K, wr, tid, 
                               I, ListenerSocketFd >>

RTStart == /\ pc[0] = "RTStart"
           /\ RTStarted' = TRUE
           /\ pc' = [pc EXCEPT ![0] = "RTLoopCheck"]
           /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, GQLock, LQA, 
                           LQAClock, LQASizes, LQB, LQBSizes, LQLocks, 
                           TaskIdCurrent, TasksFinished, RTStopped, Futures, 
                           FuturePush, tid_, task, HasWork, I_, K, wr, tid, I, 
                           ListenerSocketFd >>

RTLoopCheck == /\ pc[0] = "RTLoopCheck"
               /\ IF (TaskIdCurrent # TasksFinished)
                     THEN /\ TRUE
                          /\ pc' = [pc EXCEPT ![0] = "RTLoopCheck"]
                     ELSE /\ pc' = [pc EXCEPT ![0] = "RTFinish"]
               /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, GQLock, 
                               LQA, LQAClock, LQASizes, LQB, LQBSizes, LQLocks, 
                               TaskIdCurrent, TasksFinished, RTStarted, 
                               RTStopped, Futures, FuturePush, tid_, task, 
                               HasWork, I_, K, wr, tid, I, ListenerSocketFd >>

RTFinish == /\ pc[0] = "RTFinish"
            /\ RTStopped' = TRUE
            /\ pc' = [pc EXCEPT ![0] = "Done"]
            /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, GQLock, LQA, 
                            LQAClock, LQASizes, LQB, LQBSizes, LQLocks, 
                            TaskIdCurrent, TasksFinished, RTStarted, Futures, 
                            FuturePush, tid_, task, HasWork, I_, K, wr, tid, I, 
                            ListenerSocketFd >>

RTSpawn == RTGetNext \/ RTSpawnInit \/ RTStart \/ RTLoopCheck \/ RTFinish

WWait(self) == /\ pc[self] = "WWait"
               /\ RTStarted = TRUE
               /\ pc' = [pc EXCEPT ![self] = "Main_Loop"]
               /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, GQLock, 
                               LQA, LQAClock, LQASizes, LQB, LQBSizes, LQLocks, 
                               TaskIdCurrent, TasksFinished, RTStarted, 
                               RTStopped, Futures, FuturePush, tid_, task, 
                               HasWork, I_, K, wr, tid, I, ListenerSocketFd >>

Main_Loop(self) == /\ pc[self] = "Main_Loop"
                   /\ pc' = [pc EXCEPT ![self] = "RTStopCheck"]
                   /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                   GQLock, LQA, LQAClock, LQASizes, LQB, 
                                   LQBSizes, LQLocks, TaskIdCurrent, 
                                   TasksFinished, RTStarted, RTStopped, 
                                   Futures, FuturePush, tid_, task, HasWork, 
                                   I_, K, wr, tid, I, ListenerSocketFd >>

RTStopCheck(self) == /\ pc[self] = "RTStopCheck"
                     /\ IF RTStopped = TRUE
                           THEN /\ pc' = [pc EXCEPT ![self] = "WFinish"]
                           ELSE /\ pc' = [pc EXCEPT ![self] = "ProcessQB_LQ_Lock"]
                     /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                     GQLock, LQA, LQAClock, LQASizes, LQB, 
                                     LQBSizes, LQLocks, TaskIdCurrent, 
                                     TasksFinished, RTStarted, RTStopped, 
                                     Futures, FuturePush, tid_, task, HasWork, 
                                     I_, K, wr, tid, I, ListenerSocketFd >>

ProcessQB_LQ_Lock(self) == /\ pc[self] = "ProcessQB_LQ_Lock"
                           /\ LQLocks[self] = NullLock
                           /\ LQLocks' = [LQLocks EXCEPT ![self] = self]
                           /\ pc' = [pc EXCEPT ![self] = "LQ_Pull"]
                           /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                           GQBSize, GQLock, LQA, LQAClock, 
                                           LQASizes, LQB, LQBSizes, 
                                           TaskIdCurrent, TasksFinished, 
                                           RTStarted, RTStopped, Futures, 
                                           FuturePush, tid_, task, HasWork, I_, 
                                           K, wr, tid, I, ListenerSocketFd >>

LQ_Pull(self) == /\ pc[self] = "LQ_Pull"
                 /\ IF LQASizes[self] = 0
                       THEN /\ HasWork' = [HasWork EXCEPT ![self] = FALSE]
                            /\ UNCHANGED << LQA, LQAClock, task >>
                       ELSE /\ LQAClock' = [LQAClock EXCEPT ![self] = LQAClock[self] + 1]
                            /\ LQA' = [LQA EXCEPT ![self][LQAClock'[self]].state = TSRunning]
                            /\ task' = [task EXCEPT ![self] = LQA'[self][LQAClock'[self]]]
                            /\ HasWork' = [HasWork EXCEPT ![self] = TRUE]
                 /\ pc' = [pc EXCEPT ![self] = "LQ_Unlock"]
                 /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, GQLock, 
                                 LQASizes, LQB, LQBSizes, LQLocks, 
                                 TaskIdCurrent, TasksFinished, RTStarted, 
                                 RTStopped, Futures, FuturePush, tid_, I_, K, 
                                 wr, tid, I, ListenerSocketFd >>

LQ_Unlock(self) == /\ pc[self] = "LQ_Unlock"
                   /\ LQLocks' = [LQLocks EXCEPT ![self] = NullLock]
                   /\ pc' = [pc EXCEPT ![self] = "CheckHasWork"]
                   /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                   GQLock, LQA, LQAClock, LQASizes, LQB, 
                                   LQBSizes, TaskIdCurrent, TasksFinished, 
                                   RTStarted, RTStopped, Futures, FuturePush, 
                                   tid_, task, HasWork, I_, K, wr, tid, I, 
                                   ListenerSocketFd >>

CheckHasWork(self) == /\ pc[self] = "CheckHasWork"
                      /\ IF HasWork[self] = FALSE
                            THEN /\ TRUE
                                 /\ pc' = [pc EXCEPT ![self] = "FlushBlocked"]
                            ELSE /\ pc' = [pc EXCEPT ![self] = "Has_Work_Loop"]
                      /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                      GQLock, LQA, LQAClock, LQASizes, LQB, 
                                      LQBSizes, LQLocks, TaskIdCurrent, 
                                      TasksFinished, RTStarted, RTStopped, 
                                      Futures, FuturePush, tid_, task, HasWork, 
                                      I_, K, wr, tid, I, ListenerSocketFd >>

Has_Work_Loop(self) == /\ pc[self] = "Has_Work_Loop"
                       /\ IF HasWork[self] = TRUE
                             THEN /\ pc' = [pc EXCEPT ![self] = "DoFuturePoll"]
                             ELSE /\ pc' = [pc EXCEPT ![self] = "FlushBlocked"]
                       /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                       GQLock, LQA, LQAClock, LQASizes, LQB, 
                                       LQBSizes, LQLocks, TaskIdCurrent, 
                                       TasksFinished, RTStarted, RTStopped, 
                                       Futures, FuturePush, tid_, task, 
                                       HasWork, I_, K, wr, tid, I, 
                                       ListenerSocketFd >>

DoFuturePoll(self) == /\ pc[self] = "DoFuturePoll"
                      /\ Futures' = [Futures EXCEPT ![task[self].future] = FSPolling]
                      /\ pc' = [pc EXCEPT ![self] = "ProcessStatus"]
                      /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                      GQLock, LQA, LQAClock, LQASizes, LQB, 
                                      LQBSizes, LQLocks, TaskIdCurrent, 
                                      TasksFinished, RTStarted, RTStopped, 
                                      FuturePush, tid_, task, HasWork, I_, K, 
                                      wr, tid, I, ListenerSocketFd >>

ProcessStatus(self) == /\ pc[self] = "ProcessStatus"
                       /\ Futures[task[self].future] # FSPolling
                       /\ IF Futures[task[self].future] = FSReturned
                             THEN /\ LQA' = [LQA EXCEPT ![self][LQAClock[self]].state = TSReady]
                                  /\ UNCHANGED TasksFinished
                             ELSE /\ LQA' = [LQA EXCEPT ![self][LQAClock[self]] = NullTask]
                                  /\ TasksFinished' = TasksFinished + 1
                       /\ pc' = [pc EXCEPT ![self] = "LQ_Lock2"]
                       /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                       GQLock, LQAClock, LQASizes, LQB, 
                                       LQBSizes, LQLocks, TaskIdCurrent, 
                                       RTStarted, RTStopped, Futures, 
                                       FuturePush, tid_, task, HasWork, I_, K, 
                                       wr, tid, I, ListenerSocketFd >>

LQ_Lock2(self) == /\ pc[self] = "LQ_Lock2"
                  /\ LQLocks[self] = NullLock
                  /\ LQLocks' = [LQLocks EXCEPT ![self] = self]
                  /\ pc' = [pc EXCEPT ![self] = "LQ_Pull2"]
                  /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, GQLock, 
                                  LQA, LQAClock, LQASizes, LQB, LQBSizes, 
                                  TaskIdCurrent, TasksFinished, RTStarted, 
                                  RTStopped, Futures, FuturePush, tid_, task, 
                                  HasWork, I_, K, wr, tid, I, ListenerSocketFd >>

LQ_Pull2(self) == /\ pc[self] = "LQ_Pull2"
                  /\ IF LQASizes[self] = 0
                        THEN /\ pc' = [pc EXCEPT ![self] = "LQ_Pull_Empty2"]
                        ELSE /\ pc' = [pc EXCEPT ![self] = "UpdateLQAClock2"]
                  /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, GQLock, 
                                  LQA, LQAClock, LQASizes, LQB, LQBSizes, 
                                  LQLocks, TaskIdCurrent, TasksFinished, 
                                  RTStarted, RTStopped, Futures, FuturePush, 
                                  tid_, task, HasWork, I_, K, wr, tid, I, 
                                  ListenerSocketFd >>

LQ_Pull_Empty2(self) == /\ pc[self] = "LQ_Pull_Empty2"
                        /\ HasWork' = [HasWork EXCEPT ![self] = FALSE]
                        /\ pc' = [pc EXCEPT ![self] = "LQ_Unlock2"]
                        /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                        GQLock, LQA, LQAClock, LQASizes, LQB, 
                                        LQBSizes, LQLocks, TaskIdCurrent, 
                                        TasksFinished, RTStarted, RTStopped, 
                                        Futures, FuturePush, tid_, task, I_, K, 
                                        wr, tid, I, ListenerSocketFd >>

UpdateLQAClock2(self) == /\ pc[self] = "UpdateLQAClock2"
                         /\ IF LQAClock[self] = LQASizes[self]
                               THEN /\ HasWork' = [HasWork EXCEPT ![self] = FALSE]
                                    /\ LQLocks' = [LQLocks EXCEPT ![self] = NullLock]
                                    /\ pc' = [pc EXCEPT ![self] = "Has_Work_Loop"]
                               ELSE /\ pc' = [pc EXCEPT ![self] = "IncrementLQAClocK2"]
                                    /\ UNCHANGED << LQLocks, HasWork >>
                         /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                         GQLock, LQA, LQAClock, LQASizes, LQB, 
                                         LQBSizes, TaskIdCurrent, 
                                         TasksFinished, RTStarted, RTStopped, 
                                         Futures, FuturePush, tid_, task, I_, 
                                         K, wr, tid, I, ListenerSocketFd >>

IncrementLQAClocK2(self) == /\ pc[self] = "IncrementLQAClocK2"
                            /\ LQAClock' = [LQAClock EXCEPT ![self] = LQAClock[self] + 1]
                            /\ LQA' = [LQA EXCEPT ![self][LQAClock'[self]].state = TSRunning]
                            /\ task' = [task EXCEPT ![self] = LQA'[self][LQAClock'[self]]]
                            /\ HasWork' = [HasWork EXCEPT ![self] = TRUE]
                            /\ pc' = [pc EXCEPT ![self] = "LQ_Unlock2"]
                            /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                            GQBSize, GQLock, LQASizes, LQB, 
                                            LQBSizes, LQLocks, TaskIdCurrent, 
                                            TasksFinished, RTStarted, 
                                            RTStopped, Futures, FuturePush, 
                                            tid_, I_, K, wr, tid, I, 
                                            ListenerSocketFd >>

LQ_Unlock2(self) == /\ pc[self] = "LQ_Unlock2"
                    /\ LQLocks' = [LQLocks EXCEPT ![self] = NullLock]
                    /\ pc' = [pc EXCEPT ![self] = "Has_Work_Loop"]
                    /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                    GQLock, LQA, LQAClock, LQASizes, LQB, 
                                    LQBSizes, TaskIdCurrent, TasksFinished, 
                                    RTStarted, RTStopped, Futures, FuturePush, 
                                    tid_, task, HasWork, I_, K, wr, tid, I, 
                                    ListenerSocketFd >>

FlushBlocked(self) == /\ pc[self] = "FlushBlocked"
                      /\ TRUE
                      /\ pc' = [pc EXCEPT ![self] = "LQ_Lock3"]
                      /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                      GQLock, LQA, LQAClock, LQASizes, LQB, 
                                      LQBSizes, LQLocks, TaskIdCurrent, 
                                      TasksFinished, RTStarted, RTStopped, 
                                      Futures, FuturePush, tid_, task, HasWork, 
                                      I_, K, wr, tid, I, ListenerSocketFd >>

LQ_Lock3(self) == /\ pc[self] = "LQ_Lock3"
                  /\ LQLocks[self] = NullLock
                  /\ LQLocks' = [LQLocks EXCEPT ![self] = self]
                  /\ I_' = [I_ EXCEPT ![self] = 1]
                  /\ K' = [K EXCEPT ![self] = 0]
                  /\ pc' = [pc EXCEPT ![self] = "LQ_Flush_Loop"]
                  /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, GQLock, 
                                  LQA, LQAClock, LQASizes, LQB, LQBSizes, 
                                  TaskIdCurrent, TasksFinished, RTStarted, 
                                  RTStopped, Futures, FuturePush, tid_, task, 
                                  HasWork, wr, tid, I, ListenerSocketFd >>

LQ_Flush_Loop(self) == /\ pc[self] = "LQ_Flush_Loop"
                       /\ IF I_[self] <= LQASizes[self]
                             THEN /\ pc' = [pc EXCEPT ![self] = "LQ_Flush_Loop_Inner"]
                                  /\ UNCHANGED LQASizes
                             ELSE /\ LQASizes' = [LQASizes EXCEPT ![self] = K[self]]
                                  /\ pc' = [pc EXCEPT ![self] = "LQ_Reset_Clock"]
                       /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                       GQLock, LQA, LQAClock, LQB, LQBSizes, 
                                       LQLocks, TaskIdCurrent, TasksFinished, 
                                       RTStarted, RTStopped, Futures, 
                                       FuturePush, tid_, task, HasWork, I_, K, 
                                       wr, tid, I, ListenerSocketFd >>

LQ_Flush_Loop_Inner(self) == /\ pc[self] = "LQ_Flush_Loop_Inner"
                             /\ IF LQA[self][I_[self]] = NullTask
                                   THEN /\ pc' = [pc EXCEPT ![self] = "LQ_Flush_Step"]
                                   ELSE /\ pc' = [pc EXCEPT ![self] = "LQ_Flush_Continue"]
                             /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                             GQBSize, GQLock, LQA, LQAClock, 
                                             LQASizes, LQB, LQBSizes, LQLocks, 
                                             TaskIdCurrent, TasksFinished, 
                                             RTStarted, RTStopped, Futures, 
                                             FuturePush, tid_, task, HasWork, 
                                             I_, K, wr, tid, I, 
                                             ListenerSocketFd >>

LQ_Flush_Continue(self) == /\ pc[self] = "LQ_Flush_Continue"
                           /\ IF LQA[self][I_[self]].state = TSReady
                                 THEN /\ K' = [K EXCEPT ![self] = K[self] + 1]
                                      /\ LQA' = [LQA EXCEPT ![self][K'[self] + 1] = LQA[self][I_[self]]]
                                      /\ LQB' = LQB
                                 ELSE /\ IF LQA[self][I_[self]].state \in {TSBTimer, TSBIO}
                                            THEN /\ LQB' = [LQB EXCEPT ![self][LQBSizes[self]] = LQA[self][I_[self]]]
                                            ELSE /\ TRUE
                                                 /\ LQB' = LQB
                                      /\ UNCHANGED << LQA, K >>
                           /\ pc' = [pc EXCEPT ![self] = "LQ_Flush_Step"]
                           /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                           GQBSize, GQLock, LQAClock, LQASizes, 
                                           LQBSizes, LQLocks, TaskIdCurrent, 
                                           TasksFinished, RTStarted, RTStopped, 
                                           Futures, FuturePush, tid_, task, 
                                           HasWork, I_, wr, tid, I, 
                                           ListenerSocketFd >>

LQ_Flush_Step(self) == /\ pc[self] = "LQ_Flush_Step"
                       /\ I_' = [I_ EXCEPT ![self] = I_[self] + 1]
                       /\ pc' = [pc EXCEPT ![self] = "LQ_Flush_Loop"]
                       /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                       GQLock, LQA, LQAClock, LQASizes, LQB, 
                                       LQBSizes, LQLocks, TaskIdCurrent, 
                                       TasksFinished, RTStarted, RTStopped, 
                                       Futures, FuturePush, tid_, task, 
                                       HasWork, K, wr, tid, I, 
                                       ListenerSocketFd >>

LQ_Reset_Clock(self) == /\ pc[self] = "LQ_Reset_Clock"
                        /\ LQAClock' = [LQAClock EXCEPT ![self] = 0]
                        /\ pc' = [pc EXCEPT ![self] = "LQ_Unlock3"]
                        /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                        GQLock, LQA, LQASizes, LQB, LQBSizes, 
                                        LQLocks, TaskIdCurrent, TasksFinished, 
                                        RTStarted, RTStopped, Futures, 
                                        FuturePush, tid_, task, HasWork, I_, K, 
                                        wr, tid, I, ListenerSocketFd >>

LQ_Unlock3(self) == /\ pc[self] = "LQ_Unlock3"
                    /\ LQLocks' = [LQLocks EXCEPT ![self] = NullLock]
                    /\ pc' = [pc EXCEPT ![self] = "Main_Loop"]
                    /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                    GQLock, LQA, LQAClock, LQASizes, LQB, 
                                    LQBSizes, TaskIdCurrent, TasksFinished, 
                                    RTStarted, RTStopped, Futures, FuturePush, 
                                    tid_, task, HasWork, I_, K, wr, tid, I, 
                                    ListenerSocketFd >>

WFinish(self) == /\ pc[self] = "WFinish"
                 /\ TRUE
                 /\ pc' = [pc EXCEPT ![self] = "Done"]
                 /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, GQLock, 
                                 LQA, LQAClock, LQASizes, LQB, LQBSizes, 
                                 LQLocks, TaskIdCurrent, TasksFinished, 
                                 RTStarted, RTStopped, Futures, FuturePush, 
                                 tid_, task, HasWork, I_, K, wr, tid, I, 
                                 ListenerSocketFd >>

WorkerThread(self) == WWait(self) \/ Main_Loop(self) \/ RTStopCheck(self)
                         \/ ProcessQB_LQ_Lock(self) \/ LQ_Pull(self)
                         \/ LQ_Unlock(self) \/ CheckHasWork(self)
                         \/ Has_Work_Loop(self) \/ DoFuturePoll(self)
                         \/ ProcessStatus(self) \/ LQ_Lock2(self)
                         \/ LQ_Pull2(self) \/ LQ_Pull_Empty2(self)
                         \/ UpdateLQAClock2(self)
                         \/ IncrementLQAClocK2(self) \/ LQ_Unlock2(self)
                         \/ FlushBlocked(self) \/ LQ_Lock3(self)
                         \/ LQ_Flush_Loop(self)
                         \/ LQ_Flush_Loop_Inner(self)
                         \/ LQ_Flush_Continue(self) \/ LQ_Flush_Step(self)
                         \/ LQ_Reset_Clock(self) \/ LQ_Unlock3(self)
                         \/ WFinish(self)

TPPLoop(self) == /\ pc[self] = "TPPLoop"
                 /\ pc' = [pc EXCEPT ![self] = "TPPStart"]
                 /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, GQLock, 
                                 LQA, LQAClock, LQASizes, LQB, LQBSizes, 
                                 LQLocks, TaskIdCurrent, TasksFinished, 
                                 RTStarted, RTStopped, Futures, FuturePush, 
                                 tid_, task, HasWork, I_, K, wr, tid, I, 
                                 ListenerSocketFd >>

TPPStart(self) == /\ pc[self] = "TPPStart"
                  /\ FuturePush[wr[self]] # NullFuture \/ RTStopped
                  /\ IF RTStopped
                        THEN /\ pc' = [pc EXCEPT ![self] = "TPPDone"]
                             /\ UNCHANGED << TaskIdCurrent, tid >>
                        ELSE /\ TaskIdCurrent' = TaskIdCurrent + 1
                             /\ tid' = [tid EXCEPT ![self] = TaskIdCurrent' + 1]
                             /\ pc' = [pc EXCEPT ![self] = "TPPLockLQ"]
                  /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, GQLock, 
                                  LQA, LQAClock, LQASizes, LQB, LQBSizes, 
                                  LQLocks, TasksFinished, RTStarted, RTStopped, 
                                  Futures, FuturePush, tid_, task, HasWork, I_, 
                                  K, wr, I, ListenerSocketFd >>

TPPLockLQ(self) == /\ pc[self] = "TPPLockLQ"
                   /\ LQLocks[wr[self]] = NullLock
                   /\ LQLocks' = [LQLocks EXCEPT ![wr[self]] = wr[self]]
                   /\ pc' = [pc EXCEPT ![self] = "TPPCheckLQSize"]
                   /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                   GQLock, LQA, LQAClock, LQASizes, LQB, 
                                   LQBSizes, TaskIdCurrent, TasksFinished, 
                                   RTStarted, RTStopped, Futures, FuturePush, 
                                   tid_, task, HasWork, I_, K, wr, tid, I, 
                                   ListenerSocketFd >>

TPPCheckLQSize(self) == /\ pc[self] = "TPPCheckLQSize"
                        /\ IF LQASizes[wr[self]] = LQSize
                              THEN /\ pc' = [pc EXCEPT ![self] = "TPPLockGQ"]
                              ELSE /\ pc' = [pc EXCEPT ![self] = "TPPPushLQ"]
                        /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                        GQLock, LQA, LQAClock, LQASizes, LQB, 
                                        LQBSizes, LQLocks, TaskIdCurrent, 
                                        TasksFinished, RTStarted, RTStopped, 
                                        Futures, FuturePush, tid_, task, 
                                        HasWork, I_, K, wr, tid, I, 
                                        ListenerSocketFd >>

TPPLockGQ(self) == /\ pc[self] = "TPPLockGQ"
                   /\ GQLock = NullLock
                   /\ GQLock' = wr[self]
                   /\ pc' = [pc EXCEPT ![self] = "TPPPushGQLoop"]
                   /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, LQA, 
                                   LQAClock, LQASizes, LQB, LQBSizes, LQLocks, 
                                   TaskIdCurrent, TasksFinished, RTStarted, 
                                   RTStopped, Futures, FuturePush, tid_, task, 
                                   HasWork, I_, K, wr, tid, I, 
                                   ListenerSocketFd >>

TPPPushGQLoop(self) == /\ pc[self] = "TPPPushGQLoop"
                       /\ IF I[self] < LQSize \div 2
                             THEN /\ pc' = [pc EXCEPT ![self] = "TPPPushGQStatusCheck"]
                             ELSE /\ pc' = [pc EXCEPT ![self] = "TPPUnlockGQ"]
                       /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                       GQLock, LQA, LQAClock, LQASizes, LQB, 
                                       LQBSizes, LQLocks, TaskIdCurrent, 
                                       TasksFinished, RTStarted, RTStopped, 
                                       Futures, FuturePush, tid_, task, 
                                       HasWork, I_, K, wr, tid, I, 
                                       ListenerSocketFd >>

TPPPushGQStatusCheck(self) == /\ pc[self] = "TPPPushGQStatusCheck"
                              /\ IF LQA[wr[self]][I[self]] # NullTask
                                    THEN /\ pc' = [pc EXCEPT ![self] = "TPPPushTaskNotNull"]
                                    ELSE /\ pc' = [pc EXCEPT ![self] = "TPPGQPushWhileStep"]
                              /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                              GQBSize, GQLock, LQA, LQAClock, 
                                              LQASizes, LQB, LQBSizes, LQLocks, 
                                              TaskIdCurrent, TasksFinished, 
                                              RTStarted, RTStopped, Futures, 
                                              FuturePush, tid_, task, HasWork, 
                                              I_, K, wr, tid, I, 
                                              ListenerSocketFd >>

TPPPushTaskNotNull(self) == /\ pc[self] = "TPPPushTaskNotNull"
                            /\ IF LQA[wr[self]][I[self]].state = TSReady
                                  THEN /\ GQALast' = GQALast + 1
                                       /\ GQA' = [GQA EXCEPT ![(GQALast' % GQSize) + 1] = LQA[wr[self]][I[self]]]
                                       /\ LQA' = [LQA EXCEPT ![wr[self]][I[self]] = NullTask]
                                       /\ UNCHANGED << GQB, GQBSize >>
                                  ELSE /\ IF LQA[wr[self]][I[self]].state \in {TSBTimer, TSBIO}
                                             THEN /\ GQBSize' = GQBSize + 1
                                                  /\ GQB' = [GQB EXCEPT ![GQBSize'] = LQA[wr[self]][I[self]]]
                                                  /\ LQA' = [LQA EXCEPT ![wr[self]][I[self]] = NullTask]
                                             ELSE /\ TRUE
                                                  /\ UNCHANGED << GQB, GQBSize, 
                                                                  LQA >>
                                       /\ UNCHANGED << GQA, GQALast >>
                            /\ pc' = [pc EXCEPT ![self] = "TPPGQPushWhileStep"]
                            /\ UNCHANGED << GQAFirst, GQLock, LQAClock, 
                                            LQASizes, LQB, LQBSizes, LQLocks, 
                                            TaskIdCurrent, TasksFinished, 
                                            RTStarted, RTStopped, Futures, 
                                            FuturePush, tid_, task, HasWork, 
                                            I_, K, wr, tid, I, 
                                            ListenerSocketFd >>

TPPGQPushWhileStep(self) == /\ pc[self] = "TPPGQPushWhileStep"
                            /\ I' = [I EXCEPT ![self] = I[self] + 1]
                            /\ pc' = [pc EXCEPT ![self] = "TPPPushGQLoop"]
                            /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                            GQBSize, GQLock, LQA, LQAClock, 
                                            LQASizes, LQB, LQBSizes, LQLocks, 
                                            TaskIdCurrent, TasksFinished, 
                                            RTStarted, RTStopped, Futures, 
                                            FuturePush, tid_, task, HasWork, 
                                            I_, K, wr, tid, ListenerSocketFd >>

TPPUnlockGQ(self) == /\ pc[self] = "TPPUnlockGQ"
                     /\ GQLock' = NullLock
                     /\ pc' = [pc EXCEPT ![self] = "TPPPushLQ"]
                     /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, LQA, 
                                     LQAClock, LQASizes, LQB, LQBSizes, 
                                     LQLocks, TaskIdCurrent, TasksFinished, 
                                     RTStarted, RTStopped, Futures, FuturePush, 
                                     tid_, task, HasWork, I_, K, wr, tid, I, 
                                     ListenerSocketFd >>

TPPPushLQ(self) == /\ pc[self] = "TPPPushLQ"
                   /\ LQASizes' = [LQASizes EXCEPT ![wr[self]] = LQASizes[wr[self]] + 1]
                   /\ LQA' = [LQA EXCEPT ![wr[self]][LQASizes'[wr[self]]] = [t_id |-> tid[self], state |-> TSReady, future |-> FuturePush[wr[self]]]]
                   /\ pc' = [pc EXCEPT ![self] = "TPPReleaseLockLQAndClearFuture"]
                   /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, 
                                   GQLock, LQAClock, LQB, LQBSizes, LQLocks, 
                                   TaskIdCurrent, TasksFinished, RTStarted, 
                                   RTStopped, Futures, FuturePush, tid_, task, 
                                   HasWork, I_, K, wr, tid, I, 
                                   ListenerSocketFd >>

TPPReleaseLockLQAndClearFuture(self) == /\ pc[self] = "TPPReleaseLockLQAndClearFuture"
                                        /\ LQLocks' = [LQLocks EXCEPT ![wr[self]] = NullLock]
                                        /\ FuturePush' = [FuturePush EXCEPT ![wr[self]] = NullFuture]
                                        /\ pc' = [pc EXCEPT ![self] = "TPPLoop"]
                                        /\ UNCHANGED << GQA, GQAFirst, GQALast, 
                                                        GQB, GQBSize, GQLock, 
                                                        LQA, LQAClock, 
                                                        LQASizes, LQB, 
                                                        LQBSizes, 
                                                        TaskIdCurrent, 
                                                        TasksFinished, 
                                                        RTStarted, RTStopped, 
                                                        Futures, tid_, task, 
                                                        HasWork, I_, K, wr, 
                                                        tid, I, 
                                                        ListenerSocketFd >>

TPPDone(self) == /\ pc[self] = "TPPDone"
                 /\ TRUE
                 /\ pc' = [pc EXCEPT ![self] = "Done"]
                 /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, GQBSize, GQLock, 
                                 LQA, LQAClock, LQASizes, LQB, LQBSizes, 
                                 LQLocks, TaskIdCurrent, TasksFinished, 
                                 RTStarted, RTStopped, Futures, FuturePush, 
                                 tid_, task, HasWork, I_, K, wr, tid, I, 
                                 ListenerSocketFd >>

TaskPusherProcess(self) == TPPLoop(self) \/ TPPStart(self)
                              \/ TPPLockLQ(self) \/ TPPCheckLQSize(self)
                              \/ TPPLockGQ(self) \/ TPPPushGQLoop(self)
                              \/ TPPPushGQStatusCheck(self)
                              \/ TPPPushTaskNotNull(self)
                              \/ TPPGQPushWhileStep(self)
                              \/ TPPUnlockGQ(self) \/ TPPPushLQ(self)
                              \/ TPPReleaseLockLQAndClearFuture(self)
                              \/ TPPDone(self)

ListenerFutureStarted(self) == /\ pc[self] = "ListenerFutureStarted"
                               /\ Futures[self] = FSPolling
                               /\ ListenerSocketFd' = [ListenerSocketFd EXCEPT ![self] = 1]
                               /\ pc' = [pc EXCEPT ![self] = "ListenerFutureSocketCreatedReturn"]
                               /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                               GQBSize, GQLock, LQA, LQAClock, 
                                               LQASizes, LQB, LQBSizes, 
                                               LQLocks, TaskIdCurrent, 
                                               TasksFinished, RTStarted, 
                                               RTStopped, Futures, FuturePush, 
                                               tid_, task, HasWork, I_, K, wr, 
                                               tid, I >>

ListenerFutureSocketCreatedReturn(self) == /\ pc[self] = "ListenerFutureSocketCreatedReturn"
                                           /\ Futures' = [Futures EXCEPT ![self] = FSCompleted]
                                           /\ pc' = [pc EXCEPT ![self] = "Done"]
                                           /\ UNCHANGED << GQA, GQAFirst, 
                                                           GQALast, GQB, 
                                                           GQBSize, GQLock, 
                                                           LQA, LQAClock, 
                                                           LQASizes, LQB, 
                                                           LQBSizes, LQLocks, 
                                                           TaskIdCurrent, 
                                                           TasksFinished, 
                                                           RTStarted, 
                                                           RTStopped, 
                                                           FuturePush, tid_, 
                                                           task, HasWork, I_, 
                                                           K, wr, tid, I, 
                                                           ListenerSocketFd >>

TCPListenerFuture(self) == ListenerFutureStarted(self)
                              \/ ListenerFutureSocketCreatedReturn(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == RTSpawn
           \/ (\E self \in Workers: WorkerThread(self))
           \/ (\E self \in TaskPusherProcesses: TaskPusherProcess(self))
           \/ (\E self \in {TcpListenerFutureId}: TCPListenerFuture(self))
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ SF_vars(RTSpawn)
        /\ \A self \in Workers : SF_vars(WorkerThread(self))
        /\ \A self \in TaskPusherProcesses : SF_vars(TaskPusherProcess(self))
        /\ \A self \in {TcpListenerFutureId} : SF_vars(TCPListenerFuture(self))

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 

=============================================================================
\* Modification History
\* Last modified Sat Jun 14 19:42:46 CEST 2025 by dinu
\* Created Sat May 24 12:56:52 CEST 2025 by dinu
