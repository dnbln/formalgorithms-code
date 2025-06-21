---- MODULE MC ----
EXTENDS scheduler, TLC

\* CONSTANT definitions @modelParameterConstants:1NumWorkers
const_17505101060291753000 == 
2
----

\* CONSTANT definitions @modelParameterConstants:2GQSize
const_17505101060291754000 == 
10
----

\* CONSTANT definitions @modelParameterConstants:3LQSize
const_17505101060291755000 == 
4
----

\* CONSTANT definitions @modelParameterConstants:7KQPollNum
const_17505101060291756000 == 
1
----

\* CONSTANT definitions @modelParameterConstants:9NumFutures
const_17505101060291757000 == 
5
----

\* CONSTANT definitions @modelParameterConstants:12NumFutureSteps
const_17505101060291758000 == 
2
----

\* CONSTANT definitions @modelParameterConstants:14NumClockCyclesBeforeGQPushPull
const_17505101060291759000 == 
1
----

\* INVARIANT definition @modelCorrectnessInvariants:3
inv_17505101060291763000 ==
TasksFinished <= TaskIdCurrent
----
=============================================================================
\* Modification History
\* Created Sat Jun 21 14:48:26 CEST 2025 by dinu
