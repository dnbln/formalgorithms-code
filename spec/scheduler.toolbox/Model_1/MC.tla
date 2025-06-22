---- MODULE MC ----
EXTENDS scheduler, TLC

\* CONSTANT definitions @modelParameterConstants:1NumWorkers
const_1750578333860361000 == 
1
----

\* CONSTANT definitions @modelParameterConstants:2GQSize
const_1750578333860362000 == 
10
----

\* CONSTANT definitions @modelParameterConstants:3LQSize
const_1750578333860363000 == 
4
----

\* CONSTANT definitions @modelParameterConstants:7KQPollNum
const_1750578333860364000 == 
1
----

\* CONSTANT definitions @modelParameterConstants:9NumFutures
const_1750578333860365000 == 
5
----

\* CONSTANT definitions @modelParameterConstants:12NumFutureSteps
const_1750578333860366000 == 
1
----

\* CONSTANT definitions @modelParameterConstants:14NumClockCyclesBeforeGQPushPull
const_1750578333860367000 == 
1
----

\* INVARIANT definition @modelCorrectnessInvariants:3
inv_1750578333860371000 ==
TasksFinished <= TaskIdCurrent
----
=============================================================================
\* Modification History
\* Created Sun Jun 22 09:45:33 CEST 2025 by dinu
