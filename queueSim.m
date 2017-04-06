%  simulation for AWS queue load balancer

%%      simulation constants:

global VmMax ArrivalLambda TaskDurationLambda MaxTaskNumber NumberOfTasks;

VmMax                   = 3;
ArrivalLambda           = 0.2;
TaskDurationLambda      = 0.7;
MaxTaskNumber           = 5;
NumberOfTasks           = 1e3;

global ServiceDuration MachineState  ArrivalsDelta ArrivalTime SystemState;

%-2 undefined, -1 - off, 0 - idle, 1-MaxiTaskNumber - # of tasks
MachineState = -1:1:MaxTaskNumber; 
ArrivalsDelta = exprnd(ArrivalLambda,1,NumberOfTasks);
ArrivalTime = cumsum(ArrivalsDelta);
ServiceDuration = exprnd(TaskDurationLambda,1,NumberOfTasks);
SystemState = ones(VmMax+1,NumberOfTasks*3)*(-2);

global DeclinedCnt VmOpenCnt VmCloseCnt;
DeclinedCnt = 0;
VmOpenCnt = 0;
VmCloseCnt = 0;

%%      initiating simulation

global nextArrival;
nextArrival = 1;    %index for recalling the next arrival
lastTime = inf;

for time = 1:length(ArrivalTime)
    
    nextEventTime = min(ArrivalTime(1,time),lastTime+ServiceDuration(1,nextArrival));
    if nextEventTime < ArrivalTime(1,time)
        nextArrival = nextArrival + 1;
    end
end

%%      summary 

