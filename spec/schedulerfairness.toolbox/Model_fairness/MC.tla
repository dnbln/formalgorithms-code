---- MODULE MC ----
EXTENDS schedulerfairness, TLC

\* CONSTANT definitions @modelParameterConstants:1NumWorkers
const_1750557767391303000 == 
1
----

\* CONSTANT definitions @modelParameterConstants:2GQSize
const_1750557767391304000 == 
8
----

\* CONSTANT definitions @modelParameterConstants:3LQSize
const_1750557767391305000 == 
4
----

\* CONSTANT definitions @modelParameterConstants:6NumFutures
const_1750557767391306000 == 
6
----

\* CONSTANT definitions @modelParameterConstants:8NumFutureSteps
const_1750557767391307000 == 
3
----

\* CONSTANT definitions @modelParameterConstants:10NumClockCyclesBeforeGQPushPull
const_1750557767391308000 == 
2
----

\* CONSTANT definitions @modelParameterConstants:11NumAllowedFailedBlockedTicks
const_1750557767391309000 == 
0
----

\* INVARIANT definition @modelCorrectnessInvariants:3
inv_1750557767392313000 ==
TasksFinished <= TaskIdCurrent
----
=============================================================================
\* Modification History
\* Created Sun Jun 22 04:02:47 CEST 2025 by dinu
