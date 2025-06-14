----------------------------- MODULE scheduler -----------------------------
EXTENDS Naturals, Integers, TLC, Sequences

CONSTANT GQSize
CONSTANT LQSize
CONSTANT NumWorkers
CONSTANT NumConnections
CONSTANT NullTask
CONSTANT NullLock

ASSUME GQSize >= 1
ASSUME LQSize >= 1
ASSUME NumWorkers > 1
ASSUME NumConnections > 1

GQ == 1..GQSize
LQ == 1..LQSize
Workers == 1..NumWorkers

Task_Id == Nat

TcpListenerFutureId == NumWorkers + 1
TcpSocketFutureId == NumWorkers + 2..NumWorkers + NumConnections + 1
AllFutures == NumWorkers + 1..NumWorkers + NumConnections + 1

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

Task == [ t_id : Task_Id, state : TaskState, future : AllFutures ]
ASSUME NullTask \notin Task  
OptTask == Task \union {NullTask}

LQLocalType == [LQ -> OptTask]
LQGlobalType == [Workers -> LQLocalType]
LQSizesType == [Workers -> 0..LQSize]

LQLockType == Workers \union {NullLock}
LQLocksType == [Workers -> LQLockType]

GQType == [GQ -> OptTask]

(* --algorithm scheduler

variables
    \** Global queue
    GQA = [p \in GQ |-> NullTask]; \* Global active queue
    GQAFirst = 1; \* Global active queue first
    GQALast = 0; \* Global active queue last
    GQB = [p \in GQ |-> NullTask]; \* Global blocked queue
    
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
    Futures = [f \in AllFutures |-> FSNew]; \* Futures, for synchronization

define
    AllTasksDone == RTStarted = TRUE /\ TaskIdCurrent = TasksFinished
    AllWorkersFinished == 
        \A t \in Workers: pc[t] = "Done"
    Correct ==
        AllWorkersFinished => AllTasksDone
    TypeInvariant ==
        /\ GQA \in GQType
        /\ GQB \in GQType
        /\ LQA \in LQGlobalType
        /\ LQAClock \in LQSizesType
        /\ LQASizes \in LQSizesType
        /\ LQB \in LQGlobalType
        /\ LQBSizes \in LQSizesType
        /\ LQLocks \in LQLocksType
        /\ RTStarted \in BOOLEAN
        /\ Futures \in FuturesListType
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
            \* process qb

            \* fetch next task (opt)
            LQ_Lock:
                await LQLocks[self] = NullLock;
                LQLocks[self] := self;
            LQ_Pull:
                if LQASizes[self] = 0 then
                    LQ_Pull_Empty:
                        HasWork := FALSE;
                else
                    IncrementLQAClocK:
                        LQAClock[self] := LQAClock[self] + 1;
                    Update_State_To_Running:
                        LQA[self][LQAClock[self]].state := TSRunning;
                    LQ_Fetch_Task:
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
                            AwaitPolledFuture:
                                await Futures[task.future] # FSPolling;
                            ProcessStatus:
                                if Futures[task.future] = FSReturned then
                                    LQA[self][LQAClock[self]].state := TSReady;
                                else
                                    LQA[self][LQAClock[self]].state := TSCompleted;
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
                                    Update_State_To_Running2:
                                        LQA[self][LQAClock[self]].state := TSRunning;
                                    LQ_Fetch_Task2:
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
                        if LQA[self][I] # NullTask /\ LQA[self][I].state = TSReady then
                            Inc_K:
                                K := K + 1;
                            Update_At_K:
                                LQA[self][K] := LQA[self][I];
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
        Futures[self] := FSReturned;
end process;

fair+ process TCPSocketFuture \in TcpSocketFutureId
variables
    SocketFd = 0;
begin
    SocketFutureStarted:
        await Futures[self] = FSPolling;
        SocketFd := 1;
    SocketFutureSocketCreatedReturn:
        Futures[self] := FSReturned;
end process;
end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "ad7615e7" /\ chksum(tla) = "e17126e1")
VARIABLES pc, GQA, GQAFirst, GQALast, GQB, LQA, LQAClock, LQASizes, LQB, 
          LQBSizes, LQLocks, TaskIdCurrent, TasksFinished, RTStarted, Futures

(* define statement *)
AllTasksDone == RTStarted = TRUE /\ TaskIdCurrent = TasksFinished
AllWorkersFinished ==
    \A t \in Workers: pc[t] = "Done"
Correct ==
    AllWorkersFinished => AllTasksDone
TypeInvariant ==
    /\ GQA \in GQType
    /\ GQB \in GQType
    /\ LQA \in LQGlobalType
    /\ LQAClock \in LQSizesType
    /\ LQASizes \in LQSizesType
    /\ LQB \in LQGlobalType
    /\ LQBSizes \in LQSizesType
    /\ LQLocks \in LQLocksType
    /\ RTStarted \in BOOLEAN
    /\ Futures \in FuturesListType

VARIABLES tid, task, HasWork, I, K, ListenerSocketFd, SocketFd

vars == << pc, GQA, GQAFirst, GQALast, GQB, LQA, LQAClock, LQASizes, LQB, 
           LQBSizes, LQLocks, TaskIdCurrent, TasksFinished, RTStarted, 
           Futures, tid, task, HasWork, I, K, ListenerSocketFd, SocketFd >>

ProcSet == {0} \cup (Workers) \cup ({TcpListenerFutureId}) \cup (TcpSocketFutureId)

Init == (* Global variables *)
        /\ GQA = [p \in GQ |-> NullTask]
        /\ GQAFirst = 1
        /\ GQALast = 0
        /\ GQB = [p \in GQ |-> NullTask]
        /\ LQA = [w \in Workers |-> [p \in LQ |-> NullTask]]
        /\ LQAClock = [w \in Workers |-> 0]
        /\ LQASizes = [w \in Workers |-> 0]
        /\ LQB = [w \in Workers |-> [p \in LQ |-> NullTask]]
        /\ LQBSizes = [w \in Workers |-> 0]
        /\ LQLocks = [w \in Workers |-> NullLock]
        /\ TaskIdCurrent = 0
        /\ TasksFinished = 0
        /\ RTStarted = FALSE
        /\ Futures = [f \in AllFutures |-> FSNew]
        (* Process RTSpawn *)
        /\ tid = 0
        (* Process WorkerThread *)
        /\ task = [self \in Workers |-> NullTask]
        /\ HasWork = [self \in Workers |-> FALSE]
        /\ I = [self \in Workers |-> 1]
        /\ K = [self \in Workers |-> 1]
        (* Process TCPListenerFuture *)
        /\ ListenerSocketFd = [self \in {TcpListenerFutureId} |-> 0]
        (* Process TCPSocketFuture *)
        /\ SocketFd = [self \in TcpSocketFutureId |-> 0]
        /\ pc = [self \in ProcSet |-> CASE self = 0 -> "RTGetNext"
                                        [] self \in Workers -> "WWait"
                                        [] self \in {TcpListenerFutureId} -> "ListenerFutureStarted"
                                        [] self \in TcpSocketFutureId -> "SocketFutureStarted"]

RTGetNext == /\ pc[0] = "RTGetNext"
             /\ TaskIdCurrent' = TaskIdCurrent + 1
             /\ tid' = TaskIdCurrent' + 1
             /\ pc' = [pc EXCEPT ![0] = "RTSpawnInit"]
             /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQA, LQAClock, 
                             LQASizes, LQB, LQBSizes, LQLocks, TasksFinished, 
                             RTStarted, Futures, task, HasWork, I, K, 
                             ListenerSocketFd, SocketFd >>

RTSpawnInit == /\ pc[0] = "RTSpawnInit"
               /\ LQA' = [LQA EXCEPT ![1][1] = [ t_id |-> tid, state |-> TSReady, future |-> TcpListenerFutureId ]]
               /\ LQASizes' = [LQASizes EXCEPT ![1] = 1]
               /\ pc' = [pc EXCEPT ![0] = "RTStart"]
               /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQAClock, LQB, 
                               LQBSizes, LQLocks, TaskIdCurrent, TasksFinished, 
                               RTStarted, Futures, tid, task, HasWork, I, K, 
                               ListenerSocketFd, SocketFd >>

RTStart == /\ pc[0] = "RTStart"
           /\ RTStarted' = TRUE
           /\ pc' = [pc EXCEPT ![0] = "Done"]
           /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQA, LQAClock, 
                           LQASizes, LQB, LQBSizes, LQLocks, TaskIdCurrent, 
                           TasksFinished, Futures, tid, task, HasWork, I, K, 
                           ListenerSocketFd, SocketFd >>

RTSpawn == RTGetNext \/ RTSpawnInit \/ RTStart

WWait(self) == /\ pc[self] = "WWait"
               /\ RTStarted = TRUE
               /\ pc' = [pc EXCEPT ![self] = "Main_Loop"]
               /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQA, LQAClock, 
                               LQASizes, LQB, LQBSizes, LQLocks, TaskIdCurrent, 
                               TasksFinished, RTStarted, Futures, tid, task, 
                               HasWork, I, K, ListenerSocketFd, SocketFd >>

Main_Loop(self) == /\ pc[self] = "Main_Loop"
                   /\ pc' = [pc EXCEPT ![self] = "LQ_Lock"]
                   /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQA, LQAClock, 
                                   LQASizes, LQB, LQBSizes, LQLocks, 
                                   TaskIdCurrent, TasksFinished, RTStarted, 
                                   Futures, tid, task, HasWork, I, K, 
                                   ListenerSocketFd, SocketFd >>

LQ_Lock(self) == /\ pc[self] = "LQ_Lock"
                 /\ LQLocks[self] = NullLock
                 /\ LQLocks' = [LQLocks EXCEPT ![self] = self]
                 /\ pc' = [pc EXCEPT ![self] = "LQ_Pull"]
                 /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQA, LQAClock, 
                                 LQASizes, LQB, LQBSizes, TaskIdCurrent, 
                                 TasksFinished, RTStarted, Futures, tid, task, 
                                 HasWork, I, K, ListenerSocketFd, SocketFd >>

LQ_Pull(self) == /\ pc[self] = "LQ_Pull"
                 /\ IF LQASizes[self] = 0
                       THEN /\ pc' = [pc EXCEPT ![self] = "LQ_Pull_Empty"]
                       ELSE /\ pc' = [pc EXCEPT ![self] = "IncrementLQAClocK"]
                 /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQA, LQAClock, 
                                 LQASizes, LQB, LQBSizes, LQLocks, 
                                 TaskIdCurrent, TasksFinished, RTStarted, 
                                 Futures, tid, task, HasWork, I, K, 
                                 ListenerSocketFd, SocketFd >>

LQ_Pull_Empty(self) == /\ pc[self] = "LQ_Pull_Empty"
                       /\ HasWork' = [HasWork EXCEPT ![self] = FALSE]
                       /\ pc' = [pc EXCEPT ![self] = "LQ_Unlock"]
                       /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQA, 
                                       LQAClock, LQASizes, LQB, LQBSizes, 
                                       LQLocks, TaskIdCurrent, TasksFinished, 
                                       RTStarted, Futures, tid, task, I, K, 
                                       ListenerSocketFd, SocketFd >>

IncrementLQAClocK(self) == /\ pc[self] = "IncrementLQAClocK"
                           /\ LQAClock' = [LQAClock EXCEPT ![self] = LQAClock[self] + 1]
                           /\ pc' = [pc EXCEPT ![self] = "Update_State_To_Running"]
                           /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQA, 
                                           LQASizes, LQB, LQBSizes, LQLocks, 
                                           TaskIdCurrent, TasksFinished, 
                                           RTStarted, Futures, tid, task, 
                                           HasWork, I, K, ListenerSocketFd, 
                                           SocketFd >>

Update_State_To_Running(self) == /\ pc[self] = "Update_State_To_Running"
                                 /\ LQA' = [LQA EXCEPT ![self][LQAClock[self]].state = TSRunning]
                                 /\ pc' = [pc EXCEPT ![self] = "LQ_Fetch_Task"]
                                 /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                                 LQAClock, LQASizes, LQB, 
                                                 LQBSizes, LQLocks, 
                                                 TaskIdCurrent, TasksFinished, 
                                                 RTStarted, Futures, tid, task, 
                                                 HasWork, I, K, 
                                                 ListenerSocketFd, SocketFd >>

LQ_Fetch_Task(self) == /\ pc[self] = "LQ_Fetch_Task"
                       /\ task' = [task EXCEPT ![self] = LQA[self][LQAClock[self]]]
                       /\ HasWork' = [HasWork EXCEPT ![self] = TRUE]
                       /\ pc' = [pc EXCEPT ![self] = "LQ_Unlock"]
                       /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQA, 
                                       LQAClock, LQASizes, LQB, LQBSizes, 
                                       LQLocks, TaskIdCurrent, TasksFinished, 
                                       RTStarted, Futures, tid, I, K, 
                                       ListenerSocketFd, SocketFd >>

LQ_Unlock(self) == /\ pc[self] = "LQ_Unlock"
                   /\ LQLocks' = [LQLocks EXCEPT ![self] = NullLock]
                   /\ pc' = [pc EXCEPT ![self] = "CheckHasWork"]
                   /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQA, LQAClock, 
                                   LQASizes, LQB, LQBSizes, TaskIdCurrent, 
                                   TasksFinished, RTStarted, Futures, tid, 
                                   task, HasWork, I, K, ListenerSocketFd, 
                                   SocketFd >>

CheckHasWork(self) == /\ pc[self] = "CheckHasWork"
                      /\ IF HasWork[self] = FALSE
                            THEN /\ TRUE
                                 /\ pc' = [pc EXCEPT ![self] = "FlushBlocked"]
                            ELSE /\ pc' = [pc EXCEPT ![self] = "Has_Work_Loop"]
                      /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQA, 
                                      LQAClock, LQASizes, LQB, LQBSizes, 
                                      LQLocks, TaskIdCurrent, TasksFinished, 
                                      RTStarted, Futures, tid, task, HasWork, 
                                      I, K, ListenerSocketFd, SocketFd >>

Has_Work_Loop(self) == /\ pc[self] = "Has_Work_Loop"
                       /\ IF HasWork[self] = TRUE
                             THEN /\ pc' = [pc EXCEPT ![self] = "DoFuturePoll"]
                             ELSE /\ pc' = [pc EXCEPT ![self] = "FlushBlocked"]
                       /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQA, 
                                       LQAClock, LQASizes, LQB, LQBSizes, 
                                       LQLocks, TaskIdCurrent, TasksFinished, 
                                       RTStarted, Futures, tid, task, HasWork, 
                                       I, K, ListenerSocketFd, SocketFd >>

DoFuturePoll(self) == /\ pc[self] = "DoFuturePoll"
                      /\ Futures' = [Futures EXCEPT ![task[self].future] = FSPolling]
                      /\ pc' = [pc EXCEPT ![self] = "AwaitPolledFuture"]
                      /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQA, 
                                      LQAClock, LQASizes, LQB, LQBSizes, 
                                      LQLocks, TaskIdCurrent, TasksFinished, 
                                      RTStarted, tid, task, HasWork, I, K, 
                                      ListenerSocketFd, SocketFd >>

AwaitPolledFuture(self) == /\ pc[self] = "AwaitPolledFuture"
                           /\ Futures[task[self].future] # FSPolling
                           /\ pc' = [pc EXCEPT ![self] = "ProcessStatus"]
                           /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQA, 
                                           LQAClock, LQASizes, LQB, LQBSizes, 
                                           LQLocks, TaskIdCurrent, 
                                           TasksFinished, RTStarted, Futures, 
                                           tid, task, HasWork, I, K, 
                                           ListenerSocketFd, SocketFd >>

ProcessStatus(self) == /\ pc[self] = "ProcessStatus"
                       /\ IF Futures[task[self].future] = FSReturned
                             THEN /\ LQA' = [LQA EXCEPT ![self][LQAClock[self]].state = TSReady]
                             ELSE /\ LQA' = [LQA EXCEPT ![self][LQAClock[self]].state = TSCompleted]
                       /\ pc' = [pc EXCEPT ![self] = "LQ_Lock2"]
                       /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQAClock, 
                                       LQASizes, LQB, LQBSizes, LQLocks, 
                                       TaskIdCurrent, TasksFinished, RTStarted, 
                                       Futures, tid, task, HasWork, I, K, 
                                       ListenerSocketFd, SocketFd >>

LQ_Lock2(self) == /\ pc[self] = "LQ_Lock2"
                  /\ LQLocks[self] = NullLock
                  /\ LQLocks' = [LQLocks EXCEPT ![self] = self]
                  /\ pc' = [pc EXCEPT ![self] = "LQ_Pull2"]
                  /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQA, LQAClock, 
                                  LQASizes, LQB, LQBSizes, TaskIdCurrent, 
                                  TasksFinished, RTStarted, Futures, tid, task, 
                                  HasWork, I, K, ListenerSocketFd, SocketFd >>

LQ_Pull2(self) == /\ pc[self] = "LQ_Pull2"
                  /\ IF LQASizes[self] = 0
                        THEN /\ pc' = [pc EXCEPT ![self] = "LQ_Pull_Empty2"]
                        ELSE /\ pc' = [pc EXCEPT ![self] = "UpdateLQAClock2"]
                  /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQA, LQAClock, 
                                  LQASizes, LQB, LQBSizes, LQLocks, 
                                  TaskIdCurrent, TasksFinished, RTStarted, 
                                  Futures, tid, task, HasWork, I, K, 
                                  ListenerSocketFd, SocketFd >>

LQ_Pull_Empty2(self) == /\ pc[self] = "LQ_Pull_Empty2"
                        /\ HasWork' = [HasWork EXCEPT ![self] = FALSE]
                        /\ pc' = [pc EXCEPT ![self] = "LQ_Unlock2"]
                        /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQA, 
                                        LQAClock, LQASizes, LQB, LQBSizes, 
                                        LQLocks, TaskIdCurrent, TasksFinished, 
                                        RTStarted, Futures, tid, task, I, K, 
                                        ListenerSocketFd, SocketFd >>

UpdateLQAClock2(self) == /\ pc[self] = "UpdateLQAClock2"
                         /\ IF LQAClock[self] = LQASizes[self]
                               THEN /\ HasWork' = [HasWork EXCEPT ![self] = FALSE]
                                    /\ LQLocks' = [LQLocks EXCEPT ![self] = NullLock]
                                    /\ pc' = [pc EXCEPT ![self] = "Has_Work_Loop"]
                               ELSE /\ pc' = [pc EXCEPT ![self] = "IncrementLQAClocK2"]
                                    /\ UNCHANGED << LQLocks, HasWork >>
                         /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQA, 
                                         LQAClock, LQASizes, LQB, LQBSizes, 
                                         TaskIdCurrent, TasksFinished, 
                                         RTStarted, Futures, tid, task, I, K, 
                                         ListenerSocketFd, SocketFd >>

IncrementLQAClocK2(self) == /\ pc[self] = "IncrementLQAClocK2"
                            /\ LQAClock' = [LQAClock EXCEPT ![self] = LQAClock[self] + 1]
                            /\ pc' = [pc EXCEPT ![self] = "Update_State_To_Running2"]
                            /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQA, 
                                            LQASizes, LQB, LQBSizes, LQLocks, 
                                            TaskIdCurrent, TasksFinished, 
                                            RTStarted, Futures, tid, task, 
                                            HasWork, I, K, ListenerSocketFd, 
                                            SocketFd >>

Update_State_To_Running2(self) == /\ pc[self] = "Update_State_To_Running2"
                                  /\ LQA' = [LQA EXCEPT ![self][LQAClock[self]].state = TSRunning]
                                  /\ pc' = [pc EXCEPT ![self] = "LQ_Fetch_Task2"]
                                  /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                                  LQAClock, LQASizes, LQB, 
                                                  LQBSizes, LQLocks, 
                                                  TaskIdCurrent, TasksFinished, 
                                                  RTStarted, Futures, tid, 
                                                  task, HasWork, I, K, 
                                                  ListenerSocketFd, SocketFd >>

LQ_Fetch_Task2(self) == /\ pc[self] = "LQ_Fetch_Task2"
                        /\ task' = [task EXCEPT ![self] = LQA[self][LQAClock[self]]]
                        /\ HasWork' = [HasWork EXCEPT ![self] = TRUE]
                        /\ pc' = [pc EXCEPT ![self] = "LQ_Unlock2"]
                        /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQA, 
                                        LQAClock, LQASizes, LQB, LQBSizes, 
                                        LQLocks, TaskIdCurrent, TasksFinished, 
                                        RTStarted, Futures, tid, I, K, 
                                        ListenerSocketFd, SocketFd >>

LQ_Unlock2(self) == /\ pc[self] = "LQ_Unlock2"
                    /\ LQLocks' = [LQLocks EXCEPT ![self] = NullLock]
                    /\ pc' = [pc EXCEPT ![self] = "Has_Work_Loop"]
                    /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQA, LQAClock, 
                                    LQASizes, LQB, LQBSizes, TaskIdCurrent, 
                                    TasksFinished, RTStarted, Futures, tid, 
                                    task, HasWork, I, K, ListenerSocketFd, 
                                    SocketFd >>

FlushBlocked(self) == /\ pc[self] = "FlushBlocked"
                      /\ TRUE
                      /\ pc' = [pc EXCEPT ![self] = "LQ_Lock3"]
                      /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQA, 
                                      LQAClock, LQASizes, LQB, LQBSizes, 
                                      LQLocks, TaskIdCurrent, TasksFinished, 
                                      RTStarted, Futures, tid, task, HasWork, 
                                      I, K, ListenerSocketFd, SocketFd >>

LQ_Lock3(self) == /\ pc[self] = "LQ_Lock3"
                  /\ LQLocks[self] = NullLock
                  /\ LQLocks' = [LQLocks EXCEPT ![self] = self]
                  /\ I' = [I EXCEPT ![self] = 1]
                  /\ K' = [K EXCEPT ![self] = 0]
                  /\ pc' = [pc EXCEPT ![self] = "LQ_Flush_Loop"]
                  /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQA, LQAClock, 
                                  LQASizes, LQB, LQBSizes, TaskIdCurrent, 
                                  TasksFinished, RTStarted, Futures, tid, task, 
                                  HasWork, ListenerSocketFd, SocketFd >>

LQ_Flush_Loop(self) == /\ pc[self] = "LQ_Flush_Loop"
                       /\ IF I[self] <= LQASizes[self]
                             THEN /\ pc' = [pc EXCEPT ![self] = "LQ_Flush_Loop_Inner"]
                                  /\ UNCHANGED LQASizes
                             ELSE /\ LQASizes' = [LQASizes EXCEPT ![self] = K[self]]
                                  /\ pc' = [pc EXCEPT ![self] = "LQ_Reset_Clock"]
                       /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQA, 
                                       LQAClock, LQB, LQBSizes, LQLocks, 
                                       TaskIdCurrent, TasksFinished, RTStarted, 
                                       Futures, tid, task, HasWork, I, K, 
                                       ListenerSocketFd, SocketFd >>

LQ_Flush_Loop_Inner(self) == /\ pc[self] = "LQ_Flush_Loop_Inner"
                             /\ IF LQA[self][I[self]] # NullTask /\ LQA[self][I[self]].state = TSReady
                                   THEN /\ pc' = [pc EXCEPT ![self] = "Inc_K"]
                                   ELSE /\ pc' = [pc EXCEPT ![self] = "LQ_Flush_Step"]
                             /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQA, 
                                             LQAClock, LQASizes, LQB, LQBSizes, 
                                             LQLocks, TaskIdCurrent, 
                                             TasksFinished, RTStarted, Futures, 
                                             tid, task, HasWork, I, K, 
                                             ListenerSocketFd, SocketFd >>

Inc_K(self) == /\ pc[self] = "Inc_K"
               /\ K' = [K EXCEPT ![self] = K[self] + 1]
               /\ pc' = [pc EXCEPT ![self] = "Update_At_K"]
               /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQA, LQAClock, 
                               LQASizes, LQB, LQBSizes, LQLocks, TaskIdCurrent, 
                               TasksFinished, RTStarted, Futures, tid, task, 
                               HasWork, I, ListenerSocketFd, SocketFd >>

Update_At_K(self) == /\ pc[self] = "Update_At_K"
                     /\ LQA' = [LQA EXCEPT ![self][K[self]] = LQA[self][I[self]]]
                     /\ pc' = [pc EXCEPT ![self] = "LQ_Flush_Step"]
                     /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQAClock, 
                                     LQASizes, LQB, LQBSizes, LQLocks, 
                                     TaskIdCurrent, TasksFinished, RTStarted, 
                                     Futures, tid, task, HasWork, I, K, 
                                     ListenerSocketFd, SocketFd >>

LQ_Flush_Step(self) == /\ pc[self] = "LQ_Flush_Step"
                       /\ I' = [I EXCEPT ![self] = I[self] + 1]
                       /\ pc' = [pc EXCEPT ![self] = "LQ_Flush_Loop"]
                       /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQA, 
                                       LQAClock, LQASizes, LQB, LQBSizes, 
                                       LQLocks, TaskIdCurrent, TasksFinished, 
                                       RTStarted, Futures, tid, task, HasWork, 
                                       K, ListenerSocketFd, SocketFd >>

LQ_Reset_Clock(self) == /\ pc[self] = "LQ_Reset_Clock"
                        /\ LQAClock' = [LQAClock EXCEPT ![self] = 0]
                        /\ pc' = [pc EXCEPT ![self] = "LQ_Unlock3"]
                        /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQA, 
                                        LQASizes, LQB, LQBSizes, LQLocks, 
                                        TaskIdCurrent, TasksFinished, 
                                        RTStarted, Futures, tid, task, HasWork, 
                                        I, K, ListenerSocketFd, SocketFd >>

LQ_Unlock3(self) == /\ pc[self] = "LQ_Unlock3"
                    /\ LQLocks' = [LQLocks EXCEPT ![self] = NullLock]
                    /\ pc' = [pc EXCEPT ![self] = "Main_Loop"]
                    /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQA, LQAClock, 
                                    LQASizes, LQB, LQBSizes, TaskIdCurrent, 
                                    TasksFinished, RTStarted, Futures, tid, 
                                    task, HasWork, I, K, ListenerSocketFd, 
                                    SocketFd >>

WorkerThread(self) == WWait(self) \/ Main_Loop(self) \/ LQ_Lock(self)
                         \/ LQ_Pull(self) \/ LQ_Pull_Empty(self)
                         \/ IncrementLQAClocK(self)
                         \/ Update_State_To_Running(self)
                         \/ LQ_Fetch_Task(self) \/ LQ_Unlock(self)
                         \/ CheckHasWork(self) \/ Has_Work_Loop(self)
                         \/ DoFuturePoll(self) \/ AwaitPolledFuture(self)
                         \/ ProcessStatus(self) \/ LQ_Lock2(self)
                         \/ LQ_Pull2(self) \/ LQ_Pull_Empty2(self)
                         \/ UpdateLQAClock2(self)
                         \/ IncrementLQAClocK2(self)
                         \/ Update_State_To_Running2(self)
                         \/ LQ_Fetch_Task2(self) \/ LQ_Unlock2(self)
                         \/ FlushBlocked(self) \/ LQ_Lock3(self)
                         \/ LQ_Flush_Loop(self)
                         \/ LQ_Flush_Loop_Inner(self) \/ Inc_K(self)
                         \/ Update_At_K(self) \/ LQ_Flush_Step(self)
                         \/ LQ_Reset_Clock(self) \/ LQ_Unlock3(self)

ListenerFutureStarted(self) == /\ pc[self] = "ListenerFutureStarted"
                               /\ Futures[self] = FSPolling
                               /\ ListenerSocketFd' = [ListenerSocketFd EXCEPT ![self] = 1]
                               /\ pc' = [pc EXCEPT ![self] = "ListenerFutureSocketCreatedReturn"]
                               /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, 
                                               LQA, LQAClock, LQASizes, LQB, 
                                               LQBSizes, LQLocks, 
                                               TaskIdCurrent, TasksFinished, 
                                               RTStarted, Futures, tid, task, 
                                               HasWork, I, K, SocketFd >>

ListenerFutureSocketCreatedReturn(self) == /\ pc[self] = "ListenerFutureSocketCreatedReturn"
                                           /\ Futures' = [Futures EXCEPT ![self] = FSReturned]
                                           /\ pc' = [pc EXCEPT ![self] = "Done"]
                                           /\ UNCHANGED << GQA, GQAFirst, 
                                                           GQALast, GQB, LQA, 
                                                           LQAClock, LQASizes, 
                                                           LQB, LQBSizes, 
                                                           LQLocks, 
                                                           TaskIdCurrent, 
                                                           TasksFinished, 
                                                           RTStarted, tid, 
                                                           task, HasWork, I, K, 
                                                           ListenerSocketFd, 
                                                           SocketFd >>

TCPListenerFuture(self) == ListenerFutureStarted(self)
                              \/ ListenerFutureSocketCreatedReturn(self)

SocketFutureStarted(self) == /\ pc[self] = "SocketFutureStarted"
                             /\ Futures[self] = FSPolling
                             /\ SocketFd' = [SocketFd EXCEPT ![self] = 1]
                             /\ pc' = [pc EXCEPT ![self] = "SocketFutureSocketCreatedReturn"]
                             /\ UNCHANGED << GQA, GQAFirst, GQALast, GQB, LQA, 
                                             LQAClock, LQASizes, LQB, LQBSizes, 
                                             LQLocks, TaskIdCurrent, 
                                             TasksFinished, RTStarted, Futures, 
                                             tid, task, HasWork, I, K, 
                                             ListenerSocketFd >>

SocketFutureSocketCreatedReturn(self) == /\ pc[self] = "SocketFutureSocketCreatedReturn"
                                         /\ Futures' = [Futures EXCEPT ![self] = FSReturned]
                                         /\ pc' = [pc EXCEPT ![self] = "Done"]
                                         /\ UNCHANGED << GQA, GQAFirst, 
                                                         GQALast, GQB, LQA, 
                                                         LQAClock, LQASizes, 
                                                         LQB, LQBSizes, 
                                                         LQLocks, 
                                                         TaskIdCurrent, 
                                                         TasksFinished, 
                                                         RTStarted, tid, task, 
                                                         HasWork, I, K, 
                                                         ListenerSocketFd, 
                                                         SocketFd >>

TCPSocketFuture(self) == SocketFutureStarted(self)
                            \/ SocketFutureSocketCreatedReturn(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == RTSpawn
           \/ (\E self \in Workers: WorkerThread(self))
           \/ (\E self \in {TcpListenerFutureId}: TCPListenerFuture(self))
           \/ (\E self \in TcpSocketFutureId: TCPSocketFuture(self))
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ SF_vars(RTSpawn)
        /\ \A self \in Workers : SF_vars(WorkerThread(self))
        /\ \A self \in {TcpListenerFutureId} : SF_vars(TCPListenerFuture(self))
        /\ \A self \in TcpSocketFutureId : SF_vars(TCPSocketFuture(self))

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 

=============================================================================
\* Modification History
\* Last modified Sat Jun 14 17:13:11 CEST 2025 by dinu
\* Created Sat May 24 12:56:52 CEST 2025 by dinu
