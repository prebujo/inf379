%__________________________________________________________________________
%IMPORT DATA SECTION


%section to open files for the runs
fileNames = ["Call_007_Vehicle_03.txt","Call_018_Vehicle_05.txt","Call_035_Vehicle_07.txt","Call_080_Vehicle_20.txt","Call_130_Vehicle_40.txt"];
fileTable(1,1) = fopen(fileNames(1));
fileTable(1,2) = fopen(fileNames(2));
fileTable(1,3) = fopen(fileNames(3));
fileTable(1,4) = fopen(fileNames(4));
fileTable(1,5) = fopen(fileNames(5));

%starting seed and amount of runs (all using different seeds)
%seed = 41;
%runs = 10;

files = 5;
results = zeros(files,runs+6);
best_sol_overall = zeros(files,300);

for f = 1:files
fileID = fileTable(1,f);
%formats needed for import
formatVSpec = '%d,%d,%d,%d\n';
formatCSpec = '%d,%d,%d,%d,%d,%d,%d,%d,%d\n';
formatRSpec = '%d,%d,%d,%d,%d\n';
formatLSpec = '%d,%d,%d,%d,%d,%d\n';

fgetl(fileID);
%setting amount of Nodes from file
N = fscanf(fileID, '%d\n',1);
fgetl(fileID);
%setting amount of Vehicles from file
V = fscanf(fileID, '%d\n',1);
fgetl(fileID);
%reading the vehicle specifications from file
size_veh = [4,V];
vehicle_spec =  fscanf(fileID, formatVSpec, size_veh);
fgetl(fileID);
%reading the amount of calls from file
C = fscanf(fileID, '%d\n',1);
fgetl(fileID);
%importing calls per vehicle
veh_call = zeros(V,C+1);
for i= 1:V
    var = fgetl(fileID);
    var = var + ",";
    numbers = sscanf(var,'%d,');
    for j=1:length(numbers)
        veh_call(i,j) = numbers(j);
    end
end
fgetl(fileID);
%importing call specifications from file
size_call = [9,C];
call_spec =  fscanf(fileID, formatCSpec, size_call);
fgetl(fileID);
%importing routes
size_rout = [5,Inf];
route_spec = fscanf(fileID, formatRSpec, size_rout);
fgetl(fileID);
%importing load/loadoff specifications
size_load = [6,Inf];
load_spec = fscanf(fileID, formatLSpec, size_load);
fgetl(fileID);

%closing file
fclose(fileID);

%transpose imported data section
vehicle_spec = vehicle_spec';
call_spec = call_spec';
route_spec = route_spec';
load_spec = load_spec';

%clearing memory
clearvars -except n best_sol_overall vehicle_spec call_spec route_spec load_spec V C veh_call N fileTable runs seed files f fileTable results fileNames best_sol
%END OF IMPORT DATA SECTION
%__________________________________________________________________________

%__________________________________________________________________________
%MAIN PROGRAM
%running the program a given amount of times (given by the "runs" variable) with different random seeds each time from
%starting from a given "seed" variable.

% sol = [18,4,18,4,3,3,0,15,5,15,17,1,1,17,5,0,16,11,16,11,10,10,9,9,0,12,14,12,14,2,2,0,6,6,8,7,8,7,0,13,13];
% sol = rem_call(12, sol, V,C);
% sol = rem_call(18, sol, V,C);
% sol = ins_co(12, 1, sol, veh_call, vehicle_spec, call_spec, route_spec, load_spec, V,C,N);
% sol = rem_call(15,sol,V,C);
% sol = rem_call(5,sol,V,C);
% sol = rem_call(17,sol,V,C);
% sol = rem_call(1,sol,V,C);
% sol = ins_co(15, 2, sol, veh_call, vehicle_spec, call_spec, route_spec, load_spec, V,C,N);
% sol = ins_co(5, 2, sol, veh_call, vehicle_spec, call_spec, route_spec, load_spec, V,C,N);
% sol = ins_co(1, 2, sol, veh_call, vehicle_spec, call_spec, route_spec, load_spec, V,C,N);
% sol = ins_co(17, 2, sol, veh_call, vehicle_spec, call_spec, route_spec, load_spec, V,C,N)
% sol = rem_call(16,sol,V,C);
% sol = rem_call(11,sol,V,C);
% sol = rem_call(10,sol,V,C);
% sol = rem_call(9,sol,V,C);
% sol = ins_co(16, 3, sol, veh_call, vehicle_spec, call_spec, route_spec, load_spec, V,C,N);
% sol = ins_co(11, 3, sol, veh_call, vehicle_spec, call_spec, route_spec, load_spec, V,C,N);
% sol = ins_co(10, 3, sol, veh_call, vehicle_spec, call_spec, route_spec, load_spec, V,C,N);
% sol = ins_co(9, 3, sol, veh_call, vehicle_spec, call_spec, route_spec, load_spec, V,C,N)
% obj_s = obj_func(sol, vehicle_spec, route_spec, call_spec, load_spec, V, C, N)
% sol = rem_call(18,sol,V,C);
% 
% 
% 
% 
% sol3 = [12,4,12,4,3,3,0,15,5,5,15,1,17,17,1,0,11,16,16,11,10,9,10,9,0,14,14,2,2,0,6,6,8,7,8,7,0,13,13,18,18];
% obj_s = obj_func(sol3, vehicle_spec, route_spec, call_spec, load_spec, V, C, N)


%timing the run;
ttime = 0;

best_obj_overall=999999999;
T0 = -(max(call_spec(:,5))-2*mean(route_spec(:,5))-mean(load_spec(:,4))-mean(load_spec(:,6)))/log(0.99);
Tf = -1/log(0.01);

for j = 1:runs
    %best objective is reset each run
    best_obj = 9999999999;
    best_sol = zeros(1,2*C+V);

    %choosing a seed for this run.
    rng(seed+j-1);

    %creating the initial solution variables.
    ini_sol = zeros(1,2*C+V);
    ini_idx = 2*C+V;
    new_sol = zeros(1,2*C+V);

    %generating initial solution where dummy vehicle has all calls, assuming
    %this solution is always feasible.
    for i = C:-1:1
        ini_sol(1,ini_idx) = i;
        ini_sol(1,ini_idx-1) = i;
        ini_idx = ini_idx - 2;
    end
    %calculating objective for initial solution
    ini_obj = obj_func(ini_sol,vehicle_spec, route_spec, call_spec, load_spec, V, C, N);
    %storing initial solution
    results(f,runs+1) = ini_obj;
    %initiating the T0 and Tf to determine Cooling schedule
    
    %runnning 20 000 iterations to use random operators on the initial
    %solution,
    tstart = tic;
    T=T0;
    while(T>Tf)
        
        for i = 1:n
        %running the operator function with a random number using randi.
        %always using one of 4 operator functions based on probability. 
        %Getting a new solution in return that i will then precede to check
        %for feasibility if the operator needs that
        operatorSel = randi(100);
        new_sol = operator(operatorSel, ini_sol, veh_call, vehicle_spec, call_spec, route_spec,load_spec, C,V, N);
        %setting T based on T0 and Tf and the current run over total runs
        

        if(operatorSel>=60) %some operators do a feasibility check already.
            feas = 1;
        else
            %running feasible check on new solution if operator is not taking care of it.
            feas = feas_check(new_sol, veh_call, vehicle_spec, call_spec, route_spec, load_spec, C, V, N);
        end
        %if feasible, update initial solution
        if(feas)
            new_obj = obj_func(new_sol, vehicle_spec, route_spec, call_spec, load_spec, V, C, N);
            if(new_obj < best_obj)
                best_sol = new_sol;
                best_obj = new_obj;
            end
            if(new_obj < ini_obj)
                ini_obj = new_obj;
                ini_sol = new_sol;
            else
                x = rand;
                p = exp((-(new_obj-ini_obj)/T));
                if(rand<p)
                    ini_sol = new_sol;
                    ini_obj = new_obj;
                end
            end
        end

        end
        A = (T0-Tf)*(n+1)/n;
        B = T0 - A;
        T=A/(1+i) +B;
        en
    ttime = ttime + toc(tstart);
    %storing result..
    results(f,j) = best_obj;
    if(best_obj < best_obj_overall)
        best_obj_overall = best_obj;
        best_sol_overall(f,1:length(best_sol)) = best_sol;
    end
end

%calculating average..
results(f,2+runs) = sum(results(f,1:runs))/runs;

%storing average improvement
a(1,1:runs) = results(f,runs+1);
b = results(f,1:runs);
results(f,3+runs) = ((a-b)/a)*100;

%storing best run
results(f,4+runs) = min(results(f,1:runs));

%storing best improvement
results(f,5+runs) = (results(f,runs+1)-results(f,4+runs))/results(f,runs+1)*100;

%storing average time
results(f,6+runs) = ttime/runs;

clearvars -except T0 Tf n best_sol_overall best_obj_overall new_sol vehicle_spec call_spec route_spec load_spec V C veh_call N ini_sol ini_obj results best_obj best_sol seed runs fileTable files fileNames

end

%Print results to command window
header = {'Inst'};
for h=1:runs
    run = sprintf('Run_%d',h);
    header = [header run];
end
output = [header; [fileNames(1,1:files)' num2cell(results(:,1:runs))]];
disp(output);
header = {'Inst', 'Ini_obj','Avrg_Obj', 'Avrg_Impr', 'Best_Obj', 'Best_Impr', 'Avrg_time' };
output = [header; [fileNames(1,1:files)' num2cell(results(:,runs+1:runs+6))]];
disp(output);




%END OF MAIN PROGRAM
%__________________________________________________________________________

%__________________________________________________________________________
%FUNCTIONS SECTION
%__________________________________________________________________________
%OPERATOR SELECTION
function o = operator(operator, ini_sol, veh_call, vehicle_spec, call_spec, route_spec,load_spec, C,V, N)
if(operator <30)
    new_sol = switcheroo(ini_sol, C, V);
elseif(operator <60)
    new_sol = exchange3(ini_sol, C, V);
elseif(operator <=95)
    new_sol = insertion(ini_sol, veh_call, vehicle_spec, call_spec, route_spec,load_spec, V,C,N);
elseif(operator<=100)
    new_sol = reinsertion_L(ini_sol, veh_call, vehicle_spec, call_spec, route_spec,load_spec, V,C,N);
end
if(sum(new_sol) == 0)
    new_sol = ini_sol;
end
o = new_sol;
end

%__________________________________________________________________________
% LARGE RE-INSERT - OPERATOR
% Operator to remove and reinsert a large amount of calls into random
% vehicles. This operator relies on the remove and insertion operators and
% should not be performed very often. This operator is designed to make
% bigger leaps to avoid a search being stuck in one neighbourhood only
% performing local search there without getting any further.

function o1 = reinsertion_L(ini_sol, veh_call, vehicle_spec, call_spec, route_spec,load_spec, V,C,N)
%calculating amount of calls to be removed and reinserted.
amount = ceil(C/5);
new_sol = ini_sol;
calls = zeros(1,amount);
for i=1:amount
    c = randi(C);
    %avoid reinserting the same call twice
    while(ismember(c, calls))
        c=randi(C);
    end
    calls(1,i) = c;
    new_sol = rem_call(calls(1,i),new_sol, V, C);
end
for j=1:amount
    call = calls(1,j);
    marked = zeros(1,V);
    %trying to insert the removed calls in a random vehicle until no
    %vehicles are left.
    ins_sol = zeros(1,2*C+V);
    while(sum(marked) < V && sum(ins_sol) == 0)
        veh = randi(V);
        while(marked(1,veh))
            veh = randi(V);
        end
        %try inserting call in a cost efficient way.
        ins_sol = ins_co(call, veh, new_sol,veh_call, vehicle_spec, call_spec, route_spec,load_spec, V,C,N);
        %if it didnt work try greedy way
        if(sum(ins_sol) == 0)
            ins_sol = ins_gr(call, veh, new_sol,veh_call, vehicle_spec, call_spec, route_spec,load_spec, V,C,N);
        end
        marked(1,veh) = 1;
    end
    %if i managed to insert the current call in a vehicle i update the
    %solution
    if(sum(ins_sol) ~= 0)
        new_sol = ins_sol;
    end
    %if not the call will stay in the dummy vehicle.
end
%returning the solution with the new calls randomly removed and inserted
%again. will always return a feasible solution
    o1=new_sol;
end

%__________________________________________________________________________

%__________________________________________________________________________
%OPERATOR 3 - 3-Exchange
%Operator to make a 3-exchange for a vehicle with at least two
%pickup/deliveries

function o3 = exchange3(ini_sol, C, V)
    %not including the dummy vehicle as it wont make any difference
    %choosing randomly a vehicle.
    veh_choice = randi(V);
    veh = 1;
    %the following section finds the vehicle belonging to the chosen call
    i = 1;
    %generating the new solution
    new_sol = ini_sol;
    while(i<2*C+V)
        call = ini_sol(1,i);
        if(veh == veh_choice)
            %remembering starting index
            idx = i-1;
            %counting how many pickups/deliveries i have
            count = 0;
            while(call~=0)
                count = count + 1;
                i = i+1;
                if(i>2*C+V)
                    break;
                end
                call = ini_sol(1,i);
            end
            %if vehicle has some calls
            if(count > 2)
                choice1 = randi(count);
                choice2 = choice1;
                while(choice2 == choice1)
                    choice2 = randi(count);
                end
                choice3 = choice2;
                while(choice3 ==choice2 || choice3 == choice1)
                    choice3 = randi(count);
                end
                choice1 = choice1 + idx;
                choice2 = choice2 + idx;
                choice3 = choice3 + idx;
                %i swap one random choice with another
                new_sol(1,choice1) = ini_sol(1,choice2);
                new_sol(1,choice2) = ini_sol(1,choice3);
                new_sol(1,choice3) = ini_sol(1,choice1);
            end
            %done with swap, breaking out
            break;
        elseif(call == 0)
            veh = veh +1;
        end
        i = i+1;
    end
    o3=new_sol;
end
%__________________________________________________________________________

%__________________________________________________________________________
%OPERATOR 4 - SWITCHEROO
%Operator to switch the pickup and delivery of one random call with
%another random call.

function o4 = switcheroo(ini_sol, C, V)

    %choosing random calls to change, want always different calls
    call_choice1 = randi(C);
    call_choice2 = 0;

    while(call_choice2 == 0 || call_choice2 == call_choice1)
        call_choice2 = randi(C);
    end


    %the following section changes the calls in the new solution vector
    new_sol = ini_sol;
    for i = 1:2*C+V
        call = ini_sol(1,i);
        if(call == call_choice1)
            new_sol(1,i) = call_choice2;
        elseif(call == call_choice2)
            new_sol(1,i) = call_choice1;
        end
    end

    o4=new_sol;
end



%__________________________________________________________________________

%__________________________________________________________________________
% DUMMY INSERTION
% Operator to move one random unassigned or (dummy) call from dummy vehicle
% to first/bestfit on another vehicle. Operator selects a call from dummy
% vehicle ie. not assigned vehicle and tries to insert it into a random
% vehicle. The operator uses two different ways of inserting the call in
% the new vehicle, one that tries to be cost efficient but doesnt always
% return valid solutions and a greedy one which is more likely to be able
% to insert a call into a vehicle. This operator always returns a feasible
% solution.

function d = insertion(ini_sol, veh_call, vehicle_spec, call_spec, route_spec,load_spec, V,C,N)
    idx = 2*C + V;
    call_choice = 0;
    veh = 1;
    %choosing randomly a non zero call from the initial solution's dummy
    %vehicle
    for i=1:idx
        if(veh == V+1)
            call_choice = ini_sol(1,i - 1 + randi(idx - i+1));
        end
        call = ini_sol(1,i);
        if(call == 0)
            veh = veh + 1;
            continue;
        end
    end

    %if dummy vehicle was empty I remove a random call and insert it in a
    %random vehicle instead. could return same solution as before.
    if(call_choice == 0)
        call_choice = randi(C);
        rem_sol = rem_call(call_choice,ini_sol, V, C);
        new_sol = zeros(1,2*C+V);
        marked = zeros(1,V);
        while(sum(marked) < V && sum(new_sol) == 0)
            veh = randi(V);
            while(marked(1,veh))
                veh = randi(V);
            end
            %try inserting call in a cost efficient way.
            new_sol = ins_co(call_choice, veh, rem_sol,veh_call, vehicle_spec, call_spec, route_spec,load_spec, V,C,N);
            %if it didnt work try greedy way
            if(sum(new_sol) == 0)
                new_sol = ins_gr(call_choice, veh, rem_sol,veh_call, vehicle_spec, call_spec, route_spec,load_spec, V,C,N);
            end
            marked(1,veh) = 1;
        end
    else
        new_sol = zeros(1,2*C+V);
        marked = zeros(1,V);
        while(sum(marked) < V && sum(new_sol) == 0)
            veh = randi(V);
            while(marked(1,veh))
                veh = randi(V);
            end
            %try inserting call in a cost efficient way.
            new_sol = ins_co(call_choice, veh, ini_sol,veh_call, vehicle_spec, call_spec, route_spec,load_spec, V,C,N);
            %if it didnt work try greedy way
            if(sum(new_sol) == 0)
                new_sol = ins_gr(call_choice, veh, ini_sol,veh_call, vehicle_spec, call_spec, route_spec,load_spec, V,C,N);
            end
            marked(1,veh) = 1;
        end
    end
    d = new_sol;
end
%__________________________________________________________________________

%__________________________________________________________________________
%HELPING FUNCTIONS

%__________________________________________________________________________
% REMOVING RANDOM CALL
% Moves random car to dummy vehicle
function r = rem_call(call,ini_sol, V, C)
    length = 2*C +V;
    new_sol = zeros(1,length);
    new_idx = 1;

    for i=1:length
        if(ini_sol(1,i) ~= call)
            new_sol(1,new_idx) = ini_sol(1,i);
            new_idx = new_idx +1;
        end
    end

    new_sol(1,new_idx) = call;
    new_sol(1,new_idx+1) = call;
    r = new_sol;
end

%__________________________________________________________________________
%INSERT CALL GREEDY
%Inserts a call in the given vehicles schedule starting at idx if it is possible
%insertion of calls are based on all feasibility checks, size, time window
%and if veh can pickup call ie returns always a feasible solution or 0.
%Based on a greedy principle where the call that needs to be
%delivered/picked up first is chosen.

function i = ins_gr(call, veh, ini_sol, veh_call, veh_spec, call_spec, route_spec, load_spec, V,C,N)
    new_sol = zeros(1,2*C+V);
    new_idx = 1;
    %first finding the location of the vehicle in the given solution
    idx = 1;
    v = 1;
    while(v~=veh)
        c = ini_sol(1,idx);
        if(c == 0)
            v = v+1;
            new_idx = new_idx+1;
        elseif(c ~= call)
            new_sol(1,new_idx) = ini_sol(1,idx);
            new_idx = new_idx+1;
        end
        idx = idx+1;
    end

    if(ismember(call,veh_call(veh,2:C+1)))

        %time, stating node and cap of vehicle
        veh_t = veh_spec(veh,3);
        veh_n = veh_spec(veh,2);
        veh_cap = veh_spec(veh,4);

        %variables for the given input call
        call_ub_tw = call_spec(call, 7);
        call_size = call_spec(call, 4);
        ch_count = 1; %how many choices I currently have

        %initializing initial solution call if vehicle has one
        ini_call = ini_sol(1,idx);
        if(ini_call ~=0)
            ch_count = ch_count+1;
            ini_ub_tw = call_spec(ini_call,7);
            ini_size = call_spec(ini_call, 4);
        end

        %initializing boolean table to indicate pickup/delivery
        is_picked = zeros(1,C);

        while(ch_count>0)
            if(ini_call == 0) %either I have no more initial calls to insert
                chosen = call;
            elseif(ch_count == 1) %or I have finished delivering the input call
                chosen = ini_call;
            else %or i can choose one or the other
                if(call_ub_tw < ini_ub_tw && ((~is_picked(1,call) && (veh_cap-call_size)>0) || is_picked(1,call)) )
                    %if call has a lower ub tw and is picked up
                    %or is not and veh has enough cap
                    chosen = call;
                elseif(ini_ub_tw < call_ub_tw && ((~is_picked(1,ini_call) && (veh_cap-ini_size)>0) || is_picked(1,ini_call)))
                    chosen = ini_call;
                elseif(veh_cap-ini_size > 0 || is_picked(1,ini_call))
                    chosen = ini_call;
                elseif(veh_cap-call_size > 0 || is_picked(1,call))
                    chosen = call;
                else
                    new_sol = zeros(1,2*C+V);
                    break;
                end
            end

            %if I already picked up the chosen call i have to deliver it
            if(is_picked(1,chosen))
                targetNode = call_spec(chosen, 3);
                travel_t = route_spec((veh_n-1)*N*V+(targetNode-1)*V + veh, 4);
                veh_t = veh_t + travel_t;
                %if vehicle arrives before lower bound delivery. This should
                %never happen as lower bound always equals lower bound pickup
                %time but i left this check just in case if this sometimes is
                %the case.
                if(veh_t < call_spec(chosen,8))
                    veh_t = call_spec(chosen,8);
                end
                %if i arrive to late to deliver call I break and return a 0 solution
                if(veh_t>call_spec(chosen,9))
                    new_sol = zeros(1,2*C+V);
                    break;
                else
                    %if vehicle is there less than or equal to upperbound delivery
                    % I update the time with unloading time and vehicle node
                    veh_t = veh_t + load_spec((veh-1)*C + chosen, 5);
                    veh_n = targetNode;
                end

                %update new_sol with delivery
                new_sol(1,new_idx) = chosen;
                new_idx = new_idx + 1;
                %updating amount of possible choices
                if(chosen == call)
                    ch_count = ch_count -1;
                end
                %updating capacity of vehicle
                veh_cap = veh_cap + call_spec(chosen,4);

                %changing time-windows so this route wont be selected again
            else
                targetNode = call_spec(chosen, 2);
                travel_t = route_spec((veh_n-1)*N*V+(targetNode-1)*V + veh, 4);
                veh_t = veh_t + travel_t;
                %if vehicle arrives before lower bound pickup. update time
                if(veh_t < call_spec(chosen,6))
                    veh_t = call_spec(chosen,6);
                end
                %if i arrive too late to pick up call I break and return a 0 solution
                if(veh_t>call_spec(chosen,7))
                    new_sol = zeros(1,2*C+V);
                    break;
                else
                    %if vehicle is there less than or equal to upperbound pick
                    %up I update the time with loading time
                    veh_t = veh_t + load_spec((veh-1)*C + chosen, 3);
                    veh_n = targetNode;
                end
                %update picked up table
                is_picked(1,chosen) = 1;

                %update new_sol with delivery
                new_sol(1,new_idx) = chosen;
                new_idx = new_idx + 1;
                %updating capacity of vehicle
                veh_cap = veh_cap - call_spec(chosen,4);
            end
            %if i choose initial call update ini_call variable
            if(chosen == ini_call)
                idx = idx +1;
                ini_call = ini_sol(1,idx);
                if(ini_call == 0)
                    ch_count = ch_count -1;
                elseif(is_picked(1,ini_call))
                    ini_ub_tw = call_spec(ini_call,9);
                    ini_size = call_spec(ini_call, 4);
                else
                    ini_ub_tw = call_spec(ini_call,7);
                    ini_size = call_spec(ini_call, 4);
                end
            else %if I chose call update to delivery
                call_ub_tw = call_spec(call, 9);
            end

            %controlling veh_capacity
            if(veh_cap < 0)
                new_sol = zeros(1,2*C+V);
                break;
            end
        end
        
        if(sum(new_sol) ~= 0 && new_idx <= 2*C+V)
            while(new_idx <= 2*C +V)
                if(ini_sol(1,idx) ~=call)
                    new_sol(1,new_idx) = ini_sol(1,idx);
                    new_idx = new_idx + 1;
                end
                idx = idx +1;
            end
        end
        
    else
        new_sol = zeros(1,2*C+V);
    end
    i = new_sol;
end

%__________________________________________________________________________
% INSERT LOWEST COST
% This insert function give less often feasible solutions as greedy insert
% but it might find solutions that the greedy solution does not. It uses
% the "time" variable to insert calls in a given vehicles schedule based on
% the minimum "time" or cost it is to the next node (either the inserted
% node or the original node). the cost is based on time and not the actual
% cost and i compare the maximum of the time to get to the next call and
% the lower bound of the next calls to eachother. the lowest one is chosen
% to simulate a lowest cost schedule a vehicle can do.
function i = ins_co(call, veh, ini_sol, veh_call, veh_spec, call_spec, route_spec, load_spec, V,C,N)
    new_sol = zeros(1,2*C+V);
    new_idx = 1;
    %first finding the location of the vehicle in the given solution
    idx = 1;
    v = 1;
    while(v~=veh)
        c = ini_sol(1,idx);
        if(c == 0)
            v = v+1;
            new_idx = new_idx+1;
        elseif(c ~= call)
            new_sol(1,new_idx) = ini_sol(1,idx);
            new_idx = new_idx+1;
        end
        idx = idx+1;
    end
    
    if(ismember(call,veh_call(veh,2:C+1)))

        %time, stating node and cap of vehicle
        veh_t = veh_spec(veh,3);
        veh_n = veh_spec(veh,2);
        veh_cap = veh_spec(veh,4);

        %variables for the given input call
        call_node = call_spec(call, 2);
        call_cost_to = veh_t + route_spec((veh_n-1)*N*V+(call_node-1)*V + veh, 4);
        call_lb_tw = call_spec(call,6);
        call_time = max(call_cost_to, call_lb_tw);
        call_size = call_spec(call,4);
        ch_count = 1; %how many choices I currently have

        %initializing initial solution call if vehicle has one
        ini_call = ini_sol(1,idx);
        if(ini_call ~=0)
            ch_count = ch_count+1;
            ini_node = call_spec(ini_call,2);
            ini_cost_to = veh_t + route_spec((veh_n-1)*N*V+(ini_node-1)*V + veh, 4);
            ini_lb_tw = call_spec(ini_call,6);
            ini_time = max(ini_cost_to, ini_lb_tw);
            ini_size = call_spec(ini_call,4);
        end

        %initializing boolean table to indicate pickup/delivery
        is_picked = zeros(1,C);

        while(ch_count>0)
            if(ini_call == 0) %either I have no more initial calls to insert
                chosen = call;
            elseif(ch_count == 1) %or I have finished delivering the input call
                chosen = ini_call;
            else %or i can choose one or the other
                %choose the one with the lowest cost that I can fit on the load
                if(call_time < ini_time && ((~is_picked(1,call) && (veh_cap-call_size)>0) || is_picked(1,call)) )
                    %if call has a lower  and is picked up
                    %or is not and veh has enough cap
                    chosen = call;
                elseif(ini_time < call_time && ((~is_picked(1,ini_call) && (veh_cap-ini_size)>0) || is_picked(1,ini_call)))
                    chosen = ini_call;
                elseif(veh_cap-ini_size > 0 || is_picked(1,ini_call))
                    chosen = ini_call;
                elseif(veh_cap-call_size > 0 || is_picked(1,call))
                    chosen = call;
                else
                    new_sol = zeros(1,2*C+V);
                    break;
                end
            end

            %if I already picked up the chosen call i have to deliver it
            if(is_picked(1,chosen))
                targetNode = call_spec(chosen, 3);
                travel_t = route_spec((veh_n-1)*N*V+(targetNode-1)*V + veh, 4);
                veh_t = veh_t + travel_t;
                %if vehicle arrives before lower bound delivery. This should
                %never happen as lower bound always equals lower bound pickup
                %time but i left this check just in case if this sometimes is
                %the case.
                if(veh_t < call_spec(chosen,8))
                    veh_t = call_spec(chosen,8);
                end
                %if i arrive to late to deliver call I break and return a 0 solution
                if(veh_t>call_spec(chosen,9))
                    new_sol = zeros(1,2*C+V);
                    break;
                else
                    %if vehicle is there less than or equal to upperbound delivery
                    % I update the time with unloading time and vehicle node
                    veh_t = veh_t + load_spec((veh-1)*C + chosen, 5);
                    veh_n = targetNode;
                end

                %update new_sol with delivery
                new_sol(1,new_idx) = chosen;
                new_idx = new_idx + 1;
                %updating amount of possible choices if call is chosen
                if(chosen == call)
                    ch_count = ch_count -1;
                end
                %updating capacity of vehicle
                veh_cap = veh_cap + call_spec(chosen,4);
            else
                targetNode = call_spec(chosen, 2);
                travel_t = route_spec((veh_n-1)*N*V+(targetNode-1)*V + veh, 4);
                veh_t = veh_t + travel_t;
                %if vehicle arrives before lower bound pickup. update time
                if(veh_t < call_spec(chosen,6))
                    veh_t = call_spec(chosen,6);
                end
                %if i arrive too late to pick up call I break and return a 0 solution
                if(veh_t>call_spec(chosen,7))
                    new_sol = zeros(1,2*C+V);
                    break;
                else
                    %if vehicle is there less than or equal to upperbound pick
                    %up I update the time with loading time
                    veh_t = veh_t + load_spec((veh-1)*C + chosen, 3);
                    veh_n = targetNode;
                end
                %update picked up table
                is_picked(1,chosen) = 1;

                %update new_sol with delivery
                new_sol(1,new_idx) = chosen;
                new_idx = new_idx + 1;
                %updating capacity of vehicle
                veh_cap = veh_cap - call_spec(chosen,4);
            end
            %if i choose initial call update ini_call variable
            if(chosen == ini_call)
                idx = idx +1;
                ini_call = ini_sol(1,idx);
                if(ini_call == 0)
                    ch_count = ch_count -1;
                elseif(is_picked(1,ini_call))
                    ini_node = call_spec(ini_call,3);
                    ini_size = call_spec(ini_call,4);
                    ini_lb_tw = call_spec(ini_call,8);
                else
                    ini_node = call_spec(ini_call,2);
                    ini_size = call_spec(ini_call,4);
                    ini_lb_tw = call_spec(ini_call,6);
                end
            else %if I chose call update to delivery
                call_node = call_spec(call, 3);
                call_size = call_spec(call,4);
                call_lb_tw = call_spec(call,8);
            end
            % updating "cost" or time variables with the new vehicle node and/or
            % new calls.
            if(ini_call ~=0)
                ini_cost_to = veh_t + route_spec((veh_n-1)*N*V+(ini_node-1)*V + veh, 4);
                ini_time = max(ini_cost_to, ini_lb_tw);
            end
            call_cost_to = veh_t + route_spec((veh_n-1)*N*V+(call_node-1)*V + veh, 4);
            call_time = max(call_cost_to, call_lb_tw);
            
            %controlling veh_capacity
            if(veh_cap < 0)
                new_sol = zeros(1,2*C+V);
                break;
            end
        end
        if(sum(new_sol) ~= 0 && new_idx <= 2*C+V)
            while(new_idx <= 2*C +V)
                if(ini_sol(1,idx) ~=call)
                    new_sol(1,new_idx) = ini_sol(1,idx);
                    new_idx = new_idx + 1;
                end
                idx = idx +1;
            end
        end
    else
        new_sol = zeros(1,2*C+V);
    end
    i = new_sol;
end

%__________________________________________________________________________

%__________________________________________________________________________
%FEASIBILITY CHECKS

%__________________________________________________________________________
%FEASIBILITY CHECKS
function f = feas_check(route, veh_call, vehicle_spec, call_spec, route_spec, load_spec, C, V, N)
    feasible = 1;
    if(~feas_check1(route, veh_call, C, V))
        feasible = 0;
    end

    if(~feas_check2(route, vehicle_spec, call_spec, C,V))
        feasible = 0;
    end

    if(~feas_check3(route, vehicle_spec, call_spec, route_spec, load_spec, C, V, N))
        feasible = 0;
    end
    f = feasible;
end



%__________________________________________________________________________
%FEASIBILITY CHECK 1
%function for first feasibility check, is each call possible with the
%assigned vehicle;
function f1 = feas_check1(route, veh_call, C, V)
    feasible = 1;
    veh = 1;
    for i=1:(2*C+V)
        if(veh >= V+1)
            break;
        end
        call = route(1,i);
        if(call == 0)
            veh = veh + 1;
            continue;
        end
        y = ismember(call, veh_call(veh,2:(C+1)));
        if (~y)
            feasible = 0;
            break;
        end
    end
    f1 = feasible;
end

%__________________________________________________________________________




%__________________________________________________________________________
%FEASIBLE 2
%function for second feasibility check, is the generated routes possible
%with the load capacities given..
function f2 = feas_check2(route, vehicle_spec, call_spec, C, V)
    picked_up_calls = zeros(C,1); %boolean table to keep track of if a call
    feasible = 1; %is being picked up or delivered.
    v = 1; %starting on vehicle 1
    veh_load = 0;
    load_cap = vehicle_spec(v,4);
    for i =1:(V+2*C) %going through each element in the rd_route

        call = route(1,i);
        if(call == 0) %if i hit a zero solution i am done with the vehicle
            v = v+1; %update with next vehicle load cap etc.
            if(v == V+1)
                break;
            end
            veh_load = 0;
            load_cap = vehicle_spec(v,4);
            continue; %procede to next call in solution
        end
        call_load = call_spec(call,4);
        if(picked_up_calls(call,1) == 0)
            picked_up_calls(call,1) = 1;
            veh_load = veh_load + call_load;
        else
            veh_load = veh_load - call_load;
        end
        if(veh_load > load_cap)
            feasible = 0;
            break;
        end
    end
    f2 = feasible;
end

%__________________________________________________________________________


%__________________________________________________________________________
%FEASIBLE 3
%Function to check if calls can be done within the specified time-limit

function f3 = feas_check3(route, vehicle_spec, call_spec, route_spec, load_spec, C, V, N)
    feasible3 = 1;
    picked_up_calls = zeros(C,1); %boolean table to keep track of if a call
    %is being picked up or delivered
    v = 1;
    veh_location = vehicle_spec(v,2);
    veh_t = vehicle_spec(v,3);
    for i=1:(V+C*2)
        %setting the location of the vehicle to the start and the time to
        %the starting time of the vehicle.
        call = route(1,i);
        if(call == 0)
            v= v+1;
            if(v == V+1)
                break;
            end
            veh_location = vehicle_spec(v,2);
            veh_t = vehicle_spec(v,3); %setting current t equal start time of vehicle
            continue;
        end
        if(~picked_up_calls(call,1))
            %if not picked up move to pickup location
            call_start_node = call_spec(call,2);
            ind_route_loc = V*N*(veh_location-1) + V*(call_start_node-1) + v;
            loc2start_t = route_spec(ind_route_loc, 4);
            veh_t = veh_t + loc2start_t;
            veh_location = call_start_node;


            call_start_lb = call_spec(call,6);
            call_start_ub = call_spec(call,7);
            if(veh_t < call_start_lb)  %if we are there before pickup lower
                veh_t = call_start_lb; %bound the vehicle will wait
            end
            if(veh_t <= call_start_ub)
                call_pload_t = load_spec(C*(v-1) + call, 3); %if we made it
                veh_t = veh_t + call_pload_t;%in time we will load the pickup
                picked_up_calls(call,1) = 1;
            else
                feasible3 = 0; %if we dont make it on time the solution
                break;%will not be feasible and we will break with 0
            end
        else
            %if picked up move to delivery location
            call_end_node = call_spec(call,3);
            ind_route_loc = V*N*(veh_location-1) + V*(call_end_node-1) + v;
            loc2start_t = route_spec(ind_route_loc, 4);
            veh_t = veh_t + loc2start_t;
            veh_location = call_end_node;

            call_end_lb = call_spec(call,8);
            call_end_ub = call_spec(call,9);
            %this will never happen since lower bound delivery is always
            %equal lower bound pickup
            if(veh_t < call_end_lb)
                veh_t = call_end_lb + load_spec(C*(v-1) + call, 5);
            end
            if(veh_t <= call_end_ub)
                call_dload_t = load_spec(C*(v-1) + call, 5);
                veh_t = veh_t + call_dload_t;
            else
                feasible3 = 0;
                break;
            end
        end
    end
    f3 = feasible3;
end
%__________________________________________________________________________

%__________________________________________________________________________
%OBJECTIVE FUNCTION
%calculation of total costs i.e. objective function

function of = obj_func(route, vehicle_spec, route_spec, call_spec, load_spec, V, C, N)
    sol_c = 0;
    picked_up_calls = zeros(C,1);
    veh = 1; %setting start location for first vehicle
    veh_loc = vehicle_spec(veh,2);
    idx = 0;
    for j=1:(2*C + V)
        call = route(1, j);
        if(call == 0)
            veh = veh + 1;
            if(veh == V+1)
                idx = j+1;
                break;
            end
            veh_loc = vehicle_spec(veh,2);
            continue;
        end



        %calculating costs to get from veh_loc to pickup/delivery
        if(~picked_up_calls(call,1))
            %if not picked up move to pickup location and add costs of
            %drive
            call_start_node = call_spec(call,2);
            ind_route_loc = V*N*(veh_loc-1) + V*(call_start_node-1) + veh;
            loc2start_c = route_spec(ind_route_loc, 5);
            sol_c = sol_c + loc2start_c; %adding costs from vehicle location
            veh_loc = call_start_node;  %to pickup
            call_pload_c = load_spec(C*(veh-1) + call, 4);
            sol_c = sol_c + call_pload_c; %adding costs of loading pickup
            picked_up_calls(call,1) = 1;
        else
            %if picked up move to delivery location and add costs
            call_end_node = call_spec(call,3);
            ind_route_loc = V*N*(veh_loc-1) + V*(call_end_node-1) + veh;
            loc2end_c = route_spec(ind_route_loc, 5);
            sol_c = sol_c + loc2end_c;
            veh_loc = call_end_node;
            call_dload_c = load_spec(C*(veh-1) + call, 6);
            sol_c = sol_c + call_dload_c;
        end



    end

    %calculating costs of not picking up dummy vehicles
    while(idx <= 2*C + V) %idx is either the first pickup of the first
        call = route(1, idx); %route of dummy vehicle or bigger than 2*C + V
        if(~picked_up_calls(call,1)) %will only calculate cost of no transport once
            sol_c = sol_c + call_spec(call,5); %adding cost of not picking up
            picked_up_calls(call,1) = 1;
        end
        idx = idx +1; %skipping the delivery index
    end
    of = sol_c;
end
%__________________________________________________________________________
%END OF FUNCTIONS SECTION
%__________________________________________________________________________