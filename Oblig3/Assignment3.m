%__________________________________________________________________________
%IMPORT DATA SECTION

%formats needed for import
formatVSpec = '%d,%d,%d,%d\n';
formatCSpec = '%d,%d,%d,%d,%d,%d,%d,%d,%d\n';
formatRSpec = '%d,%d,%d,%d,%d\n';
formatLSpec = '%d,%d,%d,%d,%d,%d\n';

fileID = fopen('/home/preben/repo/inf379/Oblig3/Call_007_Vehicle_03.txt');
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
for j = 1:10
    %choosing a seed for this run.
    rng(40+j);
    
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

    %runnning 10 000 iterations to use random operators on the initial
    %solution, 
    for i = 1:10000
        %running the operator function with a random number using randi.
        %always using one of 3 operator functions. Getting a new solution
        %in return that i will then precede to check for feasibility
        new_sol = operator(randi(3), ini_sol, C, V);
        
        if(~feas_check1(new_sol, veh_call, C, V))
            disp("Feas check 1 not passed");
            continue;
        end
        
        if(~feas_check2(new_sol, vehicle_spec, call_spec, C,V)
            disp("Feas check 2 not passed");
            continue;
        end
        
        if(~feas_check3(new_sol, vehicle_spec, call_spec, route_spec, load_spec, C, V, N))
            disp("Feas check 3 not passed");
            continue;
        end
        
    end
end





    
    
    
    
clearvars -except vehicle_spec call_spec route_spec load_spec V C veh_call N ini_sol

%END OF MAIN PROGRAM
%__________________________________________________________________________

%__________________________________________________________________________
%FUNCTIONS SECTION
%__________________________________________________________________________
%OPERATOR SELECTION
function o = operator(operator, ini_sol, C,V)
    switch operator
        case 1
            new_sol = operator1(ini_sol, C, V);
        case 2
            new_sol = operator2(ini_sol, C, V);
        case 3
            new_sol = operator3(ini_sol, C, V);
        otherwise
            new_sol = 0;
    end
    o = new_sol;
end

%__________________________________________________________________________
%OPERATOR 1
%Operator to change a call from one vehicle to another.

function o1 = operator1(ini_sol, C, V)
    idx = 2*C + V;
    call_choice = 0;
    
    while(call_choice==0)
        call_choice = ini_sol(1,randi(2*C+V));
    end
    
    %the following section finds the vehicle belonging to the chosen call
    veh_choice = 0;
    choice_idx = 0;
    while(true)
        call = ini_sol(1,choice_idx);
        if(call == call_choice)
            veh_choice = veh_choice + 1;
            break;
        elseif(call == 0)
            veh_choice = veh_choice +1;
        end
        choice_idx = choice_idx +1;        
    end
    
    %As all calls are assigned to dummy in initial solution I am not
    %including dummy vehicle as an option here. This might lock possible
    %solutions if i dont include other operators to move a route back to
    %random, I will consider changing this. Since I could theoretically end up
    %picking a call from a vehicle and moving it to itsself i am doing a 
    %while loop until that is not the case.  
    new_veh = veh_choice;
    while(new_veh == veh_choice)
        new_veh = randi(V);
    end
    
    %generating new solution vector
    new_sol = zeros(1,idx);
    new_idx = 1;
    curr_veh = 1;

    i = 1;
    while( i <= 2*C+V)
        if(curr_veh == new_veh)
            call = ini_sol(1,i);
            if(call == 0) %if the vehicle has no other calls,
                new_sol(1,new_idx) = call_choice; % I will set the vehicle
                new_sol(1,new_idx+1) = call_choice; %to pick up and deliver
                new_idx = new_idx +3;  %the chosen call.
                i = i +1; %and continue the loop through the initial solution
                continue;
            else
                while(call ~= 0)
                    choice = randi(2);
                    if(choice == 1)
                        
                    
                    i = i+1;
                    call = ini_sol(1,i);
                end
                new_idx = new_idx +1;
            end
            
            
        end
        call = ini_sol(1,i);
        if(call == 0)
            curr_veh = curr_veh +1;
            i = i+1;
            continue;
        end
        
        
        i = i+1;
    end
        
            
        
            
 %   ini_rd = 0;
  %  while true
   %     ini_rd = randi(2*C+V);
    %    if(ini_sol(1,ini_rd) ~= 0)
     %   	return;
      %  end
    %end

    for i = 1:2*C+V-2
        new_sol(1,new_idx) = ini_sol(1,i);
        new_idx = new_idx +1;
    end    
    o1=new_sol;
end



%__________________________________________________________________________

%__________________________________________________________________________
%FEASIBILITY CHECKS


%__________________________________________________________________________
%FEASIBILITY CHECK 1
%function for first feasibility check, is each call possible with the 
%assigned vehicle;
function f4 = feas_check1(route, veh_call, C, V)
    feasible = 1;
    veh = 1;
    for i=1:(2*C+V)
        if(veh >= 6)
            break;
        end
        call = route(1,i);
        if(call == 0)
            veh = veh + 1;
            continue;
        end
        y = ismember(call, veh_call(veh,2:(C+1)));
        if (y == 0)
            feasible = 0;
            break;
        end
    end
    f4 = feasible;
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
            if(v == 6)
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
            if(v == 6)
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
            if(veh == 6)
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