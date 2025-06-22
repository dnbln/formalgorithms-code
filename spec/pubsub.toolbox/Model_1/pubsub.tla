------------------------------- MODULE pubsub -------------------------------
EXTENDS Naturals, Integers, TLC, Sequences

CONSTANT QSize
CONSTANT NumReceivers
CONSTANT NumMessages
CONSTANT NullMessage

ASSUME QSize >= 1
ASSUME NumMessages >= 1

QI == 1..QSize

QV == Nat
ASSUME NullMessage \notin QV
QVOpt == QV \union {NullMessage}
QT == [QI -> QVOpt]

SenderId == 0
ReceiverIds == 1..NumReceivers

MsgRange == 1..NumMessages
VersionType == 0..NumMessages

Processes == SenderId \union ReceiverIds

SeenOrMissedTy == [ReceiverIds -> [MsgRange -> BOOLEAN]]

EmptySeq == [i \in 1..0 |-> TRUE]

(* --algorithm pubsub
variables
    Q = [i \in QI |-> NullMessage];
    VC = 0;
    VS = [x \in ReceiverIds |-> 0];
    SentEnd = FALSE;
    SeenVersions = [x \in ReceiverIds |-> [m \in MsgRange |-> FALSE]];
    MissedVersions = [x \in ReceiverIds |-> [m \in MsgRange |-> FALSE]];

define
    SafetySeenOrMissed == \A r \in ReceiverIds: \A m \in MsgRange: SeenVersions[r][m] => ~(MissedVersions[r][m])
    EventuallySeenOrMissed == \A r \in ReceiverIds: \A m \in MsgRange: <>([](SeenVersions[r][m]) \/ [](MissedVersions[r][m]))
    
    TypeInvariant ==
        /\ Q \in QT
        /\ VC \in VersionType
        /\ SeenVersions \in SeenOrMissedTy
        /\ MissedVersions \in SeenOrMissedTy
end define;

fair+ process Sender \in {SenderId}
variables
    sent = 0;
begin
    SenderWhileLoop:
        while sent < NumMessages do
                VC := VC + 1;
                Q[((VC - 1) % QSize) + 1] := sent;
                sent := sent + 1;
        end while;
    SenderEnd:
        SentEnd := TRUE;
end process;

fair+ process Receiver \in ReceiverIds
begin
    RecvLoop:
        while ~ SentEnd \/ VS[self] < VC do
            await VS[self] < VC;
            MissedVersions[self] :=
                IF VC > QSize /\ VS[self] < VC - QSize
                THEN [x \in VS[self] + 1 .. VC - QSize |-> TRUE] @@ MissedVersions[self]
                ELSE MissedVersions[self];
            VS[self] :=
                IF VC > QSize /\ VS[self] < VC - QSize
                THEN VC - QSize + 1
                ELSE VS[self] + 1;
            SeenVersions[self][VS[self]] := TRUE;
        end while;
end process;

end algorithm; *)
\* BEGIN TRANSLATION (chksum(pcal) = "2e064960" /\ chksum(tla) = "be3a014c")
VARIABLES pc, Q, VC, VS, SentEnd, SeenVersions, MissedVersions

(* define statement *)
SafetySeenOrMissed == \A r \in ReceiverIds: \A m \in MsgRange: SeenVersions[r][m] => ~(MissedVersions[r][m])
EventuallySeenOrMissed == \A r \in ReceiverIds: \A m \in MsgRange: <>([](SeenVersions[r][m]) \/ [](MissedVersions[r][m]))

TypeInvariant ==
    /\ Q \in QT
    /\ VC \in VersionType
    /\ SeenVersions \in SeenOrMissedTy
    /\ MissedVersions \in SeenOrMissedTy

VARIABLE sent

vars == << pc, Q, VC, VS, SentEnd, SeenVersions, MissedVersions, sent >>

ProcSet == ({SenderId}) \cup (ReceiverIds)

Init == (* Global variables *)
        /\ Q = [i \in QI |-> NullMessage]
        /\ VC = 0
        /\ VS = [x \in ReceiverIds |-> 0]
        /\ SentEnd = FALSE
        /\ SeenVersions = [x \in ReceiverIds |-> [m \in MsgRange |-> FALSE]]
        /\ MissedVersions = [x \in ReceiverIds |-> [m \in MsgRange |-> FALSE]]
        (* Process Sender *)
        /\ sent = [self \in {SenderId} |-> 0]
        /\ pc = [self \in ProcSet |-> CASE self \in {SenderId} -> "SenderWhileLoop"
                                        [] self \in ReceiverIds -> "RecvLoop"]

SenderWhileLoop(self) == /\ pc[self] = "SenderWhileLoop"
                         /\ IF sent[self] < NumMessages
                               THEN /\ VC' = VC + 1
                                    /\ Q' = [Q EXCEPT ![((VC' - 1) % QSize) + 1] = sent[self]]
                                    /\ sent' = [sent EXCEPT ![self] = sent[self] + 1]
                                    /\ pc' = [pc EXCEPT ![self] = "SenderWhileLoop"]
                               ELSE /\ pc' = [pc EXCEPT ![self] = "SenderEnd"]
                                    /\ UNCHANGED << Q, VC, sent >>
                         /\ UNCHANGED << VS, SentEnd, SeenVersions, 
                                         MissedVersions >>

SenderEnd(self) == /\ pc[self] = "SenderEnd"
                   /\ SentEnd' = TRUE
                   /\ pc' = [pc EXCEPT ![self] = "Done"]
                   /\ UNCHANGED << Q, VC, VS, SeenVersions, MissedVersions, 
                                   sent >>

Sender(self) == SenderWhileLoop(self) \/ SenderEnd(self)

RecvLoop(self) == /\ pc[self] = "RecvLoop"
                  /\ IF ~ SentEnd \/ VS[self] < VC
                        THEN /\ VS[self] < VC
                             /\ MissedVersions' = [MissedVersions EXCEPT ![self] = IF VC > QSize /\ VS[self] < VC - QSize
                                                                                   THEN [x \in VS[self] + 1 .. VC - QSize |-> TRUE] @@ MissedVersions[self]
                                                                                   ELSE MissedVersions[self]]
                             /\ VS' = [VS EXCEPT ![self] = IF VC > QSize /\ VS[self] < VC - QSize
                                                           THEN VC - QSize + 1
                                                           ELSE VS[self] + 1]
                             /\ SeenVersions' = [SeenVersions EXCEPT ![self][VS'[self]] = TRUE]
                             /\ pc' = [pc EXCEPT ![self] = "RecvLoop"]
                        ELSE /\ pc' = [pc EXCEPT ![self] = "Done"]
                             /\ UNCHANGED << VS, SeenVersions, MissedVersions >>
                  /\ UNCHANGED << Q, VC, SentEnd, sent >>

Receiver(self) == RecvLoop(self)

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == (\E self \in {SenderId}: Sender(self))
           \/ (\E self \in ReceiverIds: Receiver(self))
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ \A self \in {SenderId} : SF_vars(Sender(self))
        /\ \A self \in ReceiverIds : SF_vars(Receiver(self))

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 

=============================================================================
\* Modification History
\* Last modified Sun Jun 22 16:56:25 CEST 2025 by dinu
\* Created Sun Jun 22 14:15:34 CEST 2025 by dinu
