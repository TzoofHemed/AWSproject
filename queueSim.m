%  simulation for AWS queue load balancer

clc;
clear all;

% simulation emums
global Head Tail;
Head                    = 1;
Tail                    = 2;

%%      simulation constants:

global VmMax ArrivalLambda TaskDurationMu MaxTaskNumber NumberOfTasks ...
    LbType;

VmMax                   = 3;
ArrivalLambda           = 0.2;
TaskDurationMu         = 2.1;
MaxTaskNumber           = 5;
NumberOfTasks           = 1e3;
%LB flavors : Generouse, 
LbType                  = 'Generouse';       


global ServiceDuration MachineState  ArrivalsDelta ArrivalTime ...
    SystemState SystemTime QueueIndices TaskQueues CurrentQueueState CurrentTasks;

%Inf - undefined, -1 - off, 0 - idle, 1-MaxTaskNumber - # of tasks
MachineState = -1:1:MaxTaskNumber; 
ArrivalsDelta = exprnd(ArrivalLambda,1,NumberOfTasks);
ArrivalTime = [cumsum(ArrivalsDelta) Inf];
ServiceDuration = exprnd(TaskDurationMu,1,NumberOfTasks);
SystemState = Inf(NumberOfTasks*2,VmMax);
SystemTime = Inf(1,NumberOfTasks*2);
QueueIndices = ones(VmMax,2);   %holds the head and tail in the task queue
TaskQueues = Inf(VmMax,MaxTaskNumber);
CurrentQueueState = ones(1,VmMax)*(-1);
CurrentTasks = Inf(1,VmMax);

global DeclinedCnt VmOpenCnt VmCloseCnt;
DeclinedCnt = 0;
VmOpenCnt = 0;
VmCloseCnt = 0;

%%      initiating simulation

global ArrivalIndex SystemIndex;
SystemIndex = 1;    % the current system state index
ArrivalIndex = 1;    % index for recalling the next arrival

%%
while ArrivalIndex <= NumberOfTasks + 1
    
    [minTask, minTaskQueue] = min(CurrentTasks(:));
    nextArrival = ArrivalTime(ArrivalIndex);
    if min(minTask, nextArrival) == Inf
        break;
    end
    
    if minTask <= nextArrival % current task has finished
        nextEventTime = minTask;
        % update the Task queue:
        TaskQueues(minTaskQueue,QueueIndices(minTaskQueue, Head)) = Inf;
        QueueIndices(minTaskQueue, Head) = ...
            mod(QueueIndices(minTaskQueue, Head), MaxTaskNumber) + 1;
        CurrentTasks(minTaskQueue) = ...
            TaskQueues(minTaskQueue,QueueIndices(minTaskQueue, Head));
        CurrentQueueState(minTaskQueue) = ...
            CurrentQueueState(minTaskQueue) - 1;
        
    else % a new task has arrived
        nextEventTime = nextArrival;
        nextTaskDuration = ServiceDuration(ArrivalIndex);
        
        %======(use LB)======%
        % change this section according to the LB's chosen behaviour
        switch LbType
            case 'Generouse'
                [chosenQueueState,chosenQueue] = min(CurrentQueueState);
            otherwise
                error('illegal LB type');
        end
        %====================%
        
        if chosenQueueState < MaxTaskNumber
            TaskQueues(chosenQueue,QueueIndices(chosenQueue, Tail)) = ...
                nextEventTime + nextTaskDuration;
            QueueIndices(chosenQueue, Tail) = ...
                mod(QueueIndices(chosenQueue, Tail), MaxTaskNumber) + 1;
            CurrentTasks(chosenQueue) = ...
                TaskQueues(chosenQueue,QueueIndices(chosenQueue, Head));
            if(chosenQueueState == -1)
                VmOpenCnt = VmOpenCnt + 1;
                CurrentQueueState(chosenQueue) = 1;
            else
                CurrentQueueState(chosenQueue) = ...
                    CurrentQueueState(chosenQueue) + 1;
            end
            
        else % chosenQueueState == MaxTaskNumber
            DeclinedCnt = DeclinedCnt + 1;
        end
        
        % updating arrival index
        ArrivalIndex = ArrivalIndex + 1;
        
    end
    
    % update system state:
    SystemTime(SystemIndex) = nextEventTime;
    SystemState(SystemIndex,:) = CurrentQueueState;
    
    % update SystemIndex:
    SystemIndex = SystemIndex + 1;
    
end

%%      summary 

