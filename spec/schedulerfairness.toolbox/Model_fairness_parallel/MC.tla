---- MODULE MC ----
EXTENDS schedulerfairness, TLC

\* CONSTANT definitions @modelParameterConstants:1NumWorkers
const_1750557774436322000 == 
2
----

\* CONSTANT definitions @modelParameterConstants:2GQSize
const_1750557774436323000 == 
8
----

\* CONSTANT definitions @modelParameterConstants:3LQSize
const_1750557774436324000 == 
4
----

\* CONSTANT definitions @modelParameterConstants:6NumFutures
const_1750557774436325000 == 
6
----

\* CONSTANT definitions @modelParameterConstants:8NumFutureSteps
const_1750557774436326000 == 
3
----

\* CONSTANT definitions @modelParameterConstants:10NumClockCyclesBeforeGQPushPull
const_1750557774436327000 == 
2
----

\* CONSTANT definitions @modelParameterConstants:11NumAllowedFailedBlockedTicks
const_1750557774436328000 == 
0
----

\* INVARIANT definition @modelCorrectnessInvariants:3
inv_1750557774436332000 ==
TasksFinished <= TaskIdCurrent
----
=============================================================================
\* Modification History
\* Created Sun Jun 22 04:02:54 CEST 2025 by dinu
