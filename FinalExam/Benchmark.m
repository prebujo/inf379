%__________________________________________________________________________
%IMPORT DATA SECTION

%formats needed for import
formatVSpec = '%d,%d,%d,%d\n';
formatCSpec = '%d,%d,%d,%d,%d,%d,%d,%d,%d\n';
formatRSpec = '%d,%d,%d,%d,%d\n';
formatLSpec = '%d,%d,%d,%d,%d,%d\n';

fileTable(1,1) = fopen('Call_007_Vehicle_03.txt');

fileID = fileTable(1,1);
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
clearvars -except vehicle_spec call_spec route_spec load_spec V C veh_call N
%END OF IMPORT DATA SECTION
%__________________________________________________________________________

%__________________________________________________________________________
%MAIN PROGRAM
%running the program 10 times with different random seeds each time from
%41-50

results = zeros(1,16);

%amount of seeds
s=10;

%timing the run;
ttime = 0;

%best solution
best_sol_overall = zeros(1,2*C+V);
best_obj_overall = 999999999;

for j = 1:s
    %choosing a seed for this run.
    rng(40+j);
    
    %creating the initial solution variables.
    ini_sol = zeros(1,2*C+V);
    ini_idx = 2*C+V;
    new_sol = zeros(1,2*C+V);
    
    n=10000;
    
    %best solution
    best_sol = zeros(1,2*C+V);
    best_obj = 999999999;
    

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
    results(1,1) = ini_obj;
    %runnning 10 000 iterations to use random operators on the initial
    %solution, 
    tstart = tic;
    for i = 1:n
        %running the operator function with a random number using randi.
        %always using one of 3 operator functions. Getting a new solution
        %in return that i will then precede to check for feasibility
        new_sol = operator(randi(5), ini_sol, C, V);
        T0 = 1000000;
        Tf = 1;
        T=T0-i*((T0-Tf)/n);
        
        %running feasible check on new solution.
        feas = feas_check(new_sol, veh_call, vehicle_spec, call_spec, route_spec, load_spec, C, V, N);
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
    ttime = ttime + toc(tstart);
    results(1,j+1) = best_obj;
    if(best_obj < best_obj_overall)
        best_obj_overall = best_obj;
        best_sol_overall = best_sol;
    end
    
end

%calculating average..
results(1,2+s) = sum(results(1,2:s+1))/s;

%storing average improvement
a(1,1:s) = results(1,1);
b = results(1,2:s+1);
results(1,3+s) = ((a-b)/a)*100;

%storing best run
results(1,4+s) = min(results(1,2:s+1));

%storing best improvement
results(1,5+s) = (results(1,1)-results(1,4+s))/results(1,1)*100;

%storing average time
results(1,6+s) = ttime/s;


    
    
    
    
clearvars -except vehicle_spec call_spec route_spec load_spec V C veh_call N ini_sol ini_obj results best_obj best_sol

%END OF MAIN PROGRAM
%__________________________________________________________________________

%__________________________________________________________________________
%FUNCTIONS SECTION
%__________________________________________________________________________
%OPERATOR SELECTION
function o = operator(operator, ini_sol, C,V)
    switch operator
        case 1
            new_sol = operator7(ini_sol, C, V);
        case 2
            new_sol = operator3(ini_sol, C, V);
        case 3
            new_sol = operator4(ini_sol, C, V);
        case 4
            new_sol = operator5(ini_sol, C, V);
        case 5
            new_sol = operator1(ini_sol,C,V);
        otherwise
            new_sol = 0;
    end
    o = new_sol;
end

%__________________________________________________________________________
%OPERATOR 1
%Operator to move one random call from one vehicle to another random 
%vehicle. Operator selects a call to move to a new vehicle and makes
%pickup/delivery schedule with one and one element from either new call or
%old schedule with 50% probablility until all elements are done.

function o1 = operator1(ini_sol, C, V)
    idx = 2*C + V;
    call_choice = 0;
    
    %choosing randomly a non zero call from the initial solution
    while(call_choice==0)
        call_choice = ini_sol(1,randi(idx));
    end
    
    %the following section finds the vehicle belonging to the chosen call
    veh_choice = 1;
    for i = 1:idx
        call = ini_sol(1,i);
        if(call == call_choice)
            break;
        elseif(call == 0)
            veh_choice = veh_choice +1;
        end        
    end
    
    %As all calls are assigned to dummy in initial solution I am not
    %including dummy vehicle as an option here. This might lock possible
    %solutions if i dont include other operators to move a route back to
    %random, I will consider changing this. Since I could theoretically end up
    %picking a call from a vehicle and moving it to itsself i am doing a 
    %while loop until that is not the case. tatt med dummy også..
    new_veh = veh_choice;
    while(new_veh == veh_choice)
        new_veh = randi(V+1);
    end
    
    %generating new solution vector
    new_sol = zeros(1,idx);
    new_idx = 1;
    curr_veh = 1;
    opt_idx = 1;
    opt = zeros(1,2);
    opt(1) = call_choice;
    i = 1;
    while(i<=idx||new_idx<=idx)
        if(curr_veh == new_veh)
            if(i>idx)
                call = 0;
            else
                call = ini_sol(1,i);
            end
            if(call == 0) %if the vehicle has no other calls,
                new_sol(1,new_idx) = call_choice; % I will set the vehicle
                new_sol(1,new_idx+1) = call_choice; %to pick up and deliver
                new_idx = new_idx +3;  %the chosen call.
                i = i +1; %and continue the loop through the initial solution
                opt(1) = 0;
                opt_idx = opt_idx-1;
            else
                opt_idx = opt_idx+1;
                opt(opt_idx) = call;
                choice_pickedup = 0;
                while(opt_idx >0)
                    choice = opt(1,randi(opt_idx));
                    %0 is only possbile when I am done with chosen call
                    if(choice == 0)
                        choice = opt(2);
                    end
                    new_sol(1,new_idx) = choice;
                    new_idx = new_idx+1;
                    if(choice == call_choice)                 
                        if(choice_pickedup)
                            opt(1) = 0;
                            opt_idx = opt_idx-1;
                        else
                            choice_pickedup = 1;
                        end
                    else
                        i = i+1;
                        if(i>idx)
                            opt_idx = opt_idx-1;
                            opt(2) = 0;                      
                        elseif(ini_sol(1,i)==0)
                            opt_idx = opt_idx -1;
                            opt(2)=0;
                        else
                            opt(2) = ini_sol(1,i);
                        end
                    end
                end
            end
            curr_veh = curr_veh+1;            
        else
            call = ini_sol(1,i);
            if(call==0)
                curr_veh = curr_veh +1;
                new_idx = new_idx+1;
            elseif(call~= call_choice)
                new_sol(1,new_idx) = ini_sol(1,i);
                new_idx = new_idx+1;
            end
            i = i+1;
        end        
    end
    o1=new_sol;
end



%__________________________________________________________________________

%__________________________________________________________________________
%OPERATOR 2
%Operator to make a swap for a vehicle with at least one pickup/delivery.

function o2 = operator2(ini_sol, C, V)
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
            if(count > 1)
                choice1 = randi(count);
                choice2 = choice1;
                while(choice2 == choice1)
                    choice2 = randi(count);
                end
                choice1 = choice1 + idx;
                choice2 = choice2 + idx;
                %i swap one random choice with another
                new_sol(1,choice1) = new_sol(1,choice2);
                new_sol(1,choice2) = ini_sol(1,choice1);
            end
            %done with swap, breaking out
            break;
        elseif(call == 0)
            veh = veh +1;
        end
        i = i+1;        
   end    
    
    o2=new_sol;
end



%__________________________________________________________________________

%__________________________________________________________________________
%OPERATOR 3
%Operator to make a 3-exchange for a vehicle with at least two 
%pickup/deliveries

function o3 = operator3(ini_sol, C, V)
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
%OPERATOR 4
%Operator to switch the pickup and delivery of one random call with 
%another random call.

function o4 = operator4(ini_sol, C, V)
    
    %choosing random calls to change, want always different calls
    call_choice1 = 0;
    call_choice2 = 0;
    
    while(call_choice1==0)
        call_choice1 = ini_sol(1,randi(2*C+V));
    end
    
    while(call_choice2 == 0 || call_choice2 == call_choice1)
        call_choice2 = ini_sol(1,randi(2*C+V));
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
%OPERATOR 5
%Operator to move one random call from one vehicle to another random 
%vehicle. Operator is behaving backwards in comparison with operator 1, ie.
%it starts the selection of calls at the end of the delivery schedule
%instead of the beginning.

function o5 = operator5(ini_sol, C, V)
    idx = 2*C + V;
    call_choice = 0;
    
    while(call_choice==0)
        call_choice = ini_sol(1,randi(2*C+V));
    end
    
    %the following section finds the vehicle belonging to the chosen call
    veh_choice = 1;
    for i = 1:idx
        call = ini_sol(1,i);
        if(call == call_choice)
            break;
        elseif(call == 0)
            veh_choice = veh_choice +1;
        end        
    end
    
    %As all calls are assigned to dummy in initial solution I am not
    %including dummy vehicle as an option here. This might lock possible
    %solutions if i dont include other operators to move a route back to
    %random, I will consider changing this. Since I could theoretically end up
    %picking a call from a vehicle and moving it to itsself i am doing a 
    %while loop until that is not the case. tatt med dummy også..
    new_veh = veh_choice;
    while(new_veh == veh_choice)
        new_veh = randi(V+1);
    end
    
    %generating new solution vector
    new_sol = zeros(1,idx);
    new_idx = idx;
    curr_veh = V+1;
    opt_idx = 1;
    opt = zeros(1,2);
    opt(1) = call_choice;
    i = idx;
    while(i>0||new_idx>0)
        if(curr_veh == new_veh)          
            if(i<1)
                call = 0;
            else
                call = ini_sol(1,i);
            end
            if(call == 0) %if the vehicle has no other calls,
                new_sol(1,new_idx) = call_choice; % I will set the vehicle
                new_sol(1,new_idx-1) = call_choice; %to pick up and deliver
                new_idx = new_idx -3;  %the chosen call.
                i = i -1; %and continue the loop through the initial solution
                opt(1) = 0;
                opt_idx = opt_idx-1;
            else
                opt_idx = opt_idx+1;
                opt(opt_idx) = call;
                choice_pickedup = 0;
                while(opt_idx >0)
                    choice = opt(1,randi(opt_idx));
                    %0 is only possbile when I am done with chosen call
                    if(choice == 0)
                        choice = opt(2);
                    end
                    new_sol(1,new_idx) = choice;
                    new_idx = new_idx-1;
                    if(choice == call_choice)                 
                        if(choice_pickedup)
                            opt(1) = 0;
                            opt_idx = opt_idx-1;
                        else
                            choice_pickedup = 1;
                        end
                    else
                        i = i-1;
                        if(i<1)
                            opt_idx = opt_idx-1;
                            opt(2) = 0;                      
                        elseif(ini_sol(1,i)==0)
                            opt_idx = opt_idx -1;
                            opt(2)=0;
                        else
                            opt(2) = ini_sol(1,i);
                        end
                    end
                end
            end
            curr_veh = curr_veh-1;            
        else
            call = ini_sol(1,i);
            if(call==0)
                curr_veh = curr_veh -1;
                new_idx = new_idx-1;
            elseif(call~= call_choice)
                new_sol(1,new_idx) = ini_sol(1,i);
                new_idx = new_idx-1;
            end
            i = i-1;
        end        
    end
    o5=new_sol;
end



%__________________________________________________________________________

%__________________________________________________________________________
%OPERATOR 6
%Operator to move one random call from one vehicle to another random 
%vehicle. Operator puts pickup and delivery in the end of the vehicles
%schedule.

function o6 = operator6(ini_sol, C, V)
    idx = 2*C + V;
    call_choice = 0;
    
    while(call_choice==0)
        call_choice = ini_sol(1,randi(2*C+V));
    end
    
    %the following section finds the vehicle belonging to the chosen call
    veh_choice = 1;
    for i = 1:2*C+V
        call = ini_sol(1,i);
        if(call == call_choice)
            break;
        elseif(call == 0)
            veh_choice = veh_choice +1;
        end        
    end
    
    %As all calls are assigned to dummy in initial solution I am not
    %including dummy vehicle as an option here. This might lock possible
    %solutions if i dont include other operators to move a route back to
    %random, I will consider changing this. Since I could theoretically end up
    %picking a call from a vehicle and moving it to itsself i am doing a 
    %while loop until that is not the case. tatt med dummy også..
    new_veh = veh_choice;
    while(new_veh == veh_choice)
        new_veh = randi(V+1);
    end
    
    %generating new solution vector
    new_sol = zeros(1,idx);
    new_idx = 1;
    curr_veh = 1;
    i = 1;
    while(i<=idx || new_idx<=idx)
        if(i>2*C+V)
            call = 0;
        else
            call = ini_sol(1,i);
        end
        %if I am at the end of the new vehicles schedule
        if(call == 0 && curr_veh == new_veh) 
            new_sol(1,new_idx) = call_choice; % I will set the vehicle
            new_sol(1,new_idx+1) = call_choice; %to pick up and deliver
            new_idx = new_idx +3;  %the chosen call.
            i = i +1; %and continue the loop through the initial solution
            curr_veh = curr_veh+1;
        elseif(call == 0)
            curr_veh = curr_veh+1;
            i = i+1;
            new_idx = new_idx+1;
        elseif(call == call_choice)
            i = i+1;
        else
            new_sol(1,new_idx) = call;
            new_idx = new_idx+1;
            i = i+1;
        end
    end
    o6=new_sol;
end



%__________________________________________________________________________

%__________________________________________________________________________
%OPERATOR 7
%Operator to move one random call from one vehicle to another random 
%vehicle. Call pickup and delivery are randomly inserted into the new
%vehicle.

function o7 = operator7(ini_sol, C, V)
    idx = 2*C + V;
    call_choice = 0;
    
    %choosing randomly a non zero call from the initial solution
    while(call_choice==0)
        call_choice = ini_sol(1,randi(idx));
    end
    
    %the following section finds the vehicle belonging to the chosen call
    veh_choice = 1;
    for i = 1:idx
        call = ini_sol(1,i);
        if(call == call_choice)
            break;
        elseif(call == 0)
            veh_choice = veh_choice +1;
        end        
    end
    
    %As all calls are assigned to dummy in initial solution I am not
    %including dummy vehicle as an option here. This might lock possible
    %solutions if i dont include other operators to move a route back to
    %random, I will consider changing this. Since I could theoretically end up
    %picking a call from a vehicle and moving it to itsself i am doing a 
    %while loop until that is not the case. tatt med dummy også..
    new_veh = veh_choice;
    while(new_veh == veh_choice)
        new_veh = randi(V+1);
    end
    
    %generating new solution vector
    new_sol = zeros(1,idx);
    new_idx = 1;
    curr_veh = 1;
    opt_idx = 0;
    i = 1;
    while(i<=idx||new_idx<=idx)
        if(curr_veh == new_veh)
            if(i>idx)
                call = 0;
            else
                call = ini_sol(1,i);
            end
            if(call == 0) %if the vehicle has no other calls,
                new_sol(1,new_idx) = call_choice; % I will set the vehicle
                new_sol(1,new_idx+1) = call_choice; %to pick up and deliver
                new_idx = new_idx +2;  %the chosen call.
            else
                k = i;
                while(call ~=0)
                    opt_idx = opt_idx+1;
                    k = k+1;
                    if(k>idx)
                        call = 0;
                    else
                        call = ini_sol(1,k);
                    end
                end
                %setting random indexes in the vehicles schedule (now
                %increased with 2 because of new call
                pickupat = new_idx+ randi(opt_idx +2)-1;
                deliveryat = pickupat;
                while(pickupat == deliveryat)
                    deliveryat = new_idx+ randi(opt_idx +2)-1;
                end
                
                %setting the calls pickup and delivery.
                new_sol(1,pickupat) = call_choice;
                new_sol(1,deliveryat) = call_choice;
                
                %setting the rest of the schedule.
                c = 2;
                while(i < k)
                    if(new_idx==pickupat||new_idx==deliveryat)
                        new_idx = new_idx+1;
                        c = c-1;
                    else
                        new_sol(1,new_idx)=ini_sol(1,i);
                        new_idx = new_idx+1;
                        i = i+1;
                    end
                end
                new_idx = new_idx + c;
            end
            i = i+1;
            new_idx = new_idx+1;
            curr_veh = curr_veh+1;            
        else
            call = ini_sol(1,i);
            if(call==0)
                curr_veh = curr_veh +1;
                new_idx = new_idx+1;
            elseif(call~= call_choice)
                new_sol(1,new_idx) = ini_sol(1,i);
                new_idx = new_idx+1;
            end
            i =i+1;
        end        
    end
    o7=new_sol;
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
            if(veh_t < call_end_lb)
                veh_t = call_end_lb;
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