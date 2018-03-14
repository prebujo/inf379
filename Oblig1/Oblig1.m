

%__________________________________________________________________________
%IMPORT DATA SECTION
%__________________________________________________________________________

%formats needed for import
formatVSpec = '%d,%d,%d,%d\n';
formatCSpec = '%d,%d,%d,%d,%d,%d,%d,%d,%d\n';
formatRSpec = '%d,%d,%d,%d,%d\n';
formatLSpec = '%d,%d,%d,%d,%d,%d\n';

fileID = fopen('/home/preben/Downloads/Call_18_Vehicle_5.txt');
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
%__________________________________________________________________________
%END OF IMPORT DATA SECTION
%__________________________________________________________________________




%__________________________________________________________________________
%MAIN PROGRAM
%__________________________________________________________________________
%
%in the following section is the code that will run and call upon helping
%functions to generate random routes for each vehicle and perform
%feasibility checks. In the end the solution of the program will be
%reported out to the screen.

M = 10000; %number of random solutions generated

feas_idx = 1; %index to keep track of each feasible solution

%matrix for feasible solutions to plot/output
feas_sol = zeros(M/500,2*C+V); % getting less than 0,2% feasible solutions
feas_obj_plot = zeros(M/500,2);%
obj_plot = zeros(M,1);

%best objective function variables
best_objective = 999999999999;
best_solution = zeros(1,2*C+V);
best_iter = 0;

%variable for first feasible solution

first_feas_iter = 0;

for i=1:M
    %generating a random solution of vehicle-call pairs
    rd_sol = rand_sol(V,C);
    
    %Generating random pickup/delivery schedule for each vehicle
    rd_route = rand_route_sol(rd_sol, C, V);
    
    %saving objective function of route for plot
    obj_plot(i,1) = obj_func(rd_route, vehicle_spec, route_spec, call_spec, load_spec, V, C, N);

    %Calling feasibility check 1 to check to see if calls can be picked up
    %feasible1 = feas_check1(rd_sol, veh_call, C);
    feasible1 = feas_check1(rd_sol, veh_call,C,V);    
    
    if ~(feasible1) %if not feasable i will continue to generate a new
        continue    %solution
    end  

    
    
    %Running feasibility check 2 to see if each cars load capasities hold
    feasible2 = feas_check2(rd_route, vehicle_spec, call_spec, C, V);
    
    if ~(feasible2) %if not feasable i will continue to generate a new
        continue    %solution
    end 
    %Running feasibility check 3 to see if delivery can be done on time
    feasible3 = feas_check3(rd_route, vehicle_spec, call_spec, route_spec, load_spec, C, V, N);
    if ~(feasible3) %if not feasable i will continue to generate a new
        continue    %solution
    end 
    %writing feasible solution to the feasible solution matrix
    feas_sol(feas_idx,:) = rd_route;
    
    %calculating and saving objective function and iterations
    feas_obj_plot(feas_idx,1) = obj_func(rd_route, vehicle_spec, route_spec, call_spec, load_spec, V, C, N);   
    feas_obj_plot(feas_idx,2) = i;
    
    %saving best objective function
    if (feas_obj_plot(feas_idx,1) < best_objective) %if its better
        best_objective = feas_obj_plot(feas_idx,1);
        best_sol = feas_sol(feas_idx, :);
        best_iter = i;
    end   
    
    %updating feasable solution index
    feas_idx = feas_idx +1;
    
end
clearvars -except best_iter obj_plot first_feas_iter M best_objective best_sol vehicle_spec objective call_spec route_spec load_spec V C veh_call feas_sol feas_idx N rd_sol feas_obj_plot ;  

%Reporting solution
fprintf('The first feasible solution was found after %d iterations: \n', feas_obj_plot(1,2));
veh = 1;
fprintf('Vehicle 1:')
for i=1:C*2+V
    call = feas_sol(1,i);
    if(call == 0)
        veh = veh +1;
        if(veh == 6)
            fprintf('\nNot transported:');
            continue;
        else
            fprintf('\nVehicle %d:', veh);
            continue;
        end
    end
    fprintf(' %d', call);
end
fprintf('\nThe objective function of the first solution was %d \n\n', feas_obj_plot(1,1));

fprintf('\nThe best solution of the %d iterations was found after %d iterations: \n', M, best_iter);

veh = 1;

fprintf('Vehicle 1:')
for i=1:C*2+V
    call = best_sol(1,i);
    if(call == 0)
        veh = veh +1;
        if(veh == 6)
            fprintf('\nNot transported:');
            continue;
        else
            fprintf('\nVehicle %d:', veh);
            continue;
        end
    end
    fprintf(' %d', call);
end

fprintf('\nThe objective function of the best solution was %d \n\n', best_objective);

%Plotting obj func of feasible solutions against all objective functions
plot(1:10000, obj_plot);
hold on;
plot(feas_obj_plot(1:(feas_idx-1),2),feas_obj_plot(1:(feas_idx-1),1),'*');
hold off;
title('Objective solutions');
xlabel('iterations');
ylabel('value');
legend('all solutions', 'feasible solutions', 'Location','southeast');


%__________________________________________________________________________
%END OF MAIN PROGRAM
%__________________________________________________________________________



%__________________________________________________________________________
%FUNCTIONS SECTION

%__________________________________________________________________________
%ROUTES GENERATION
%Function to assign random calls to each vehicle, each vehicle is separated
%with a 0 in a 1x(V+C) matrix
function r2 = rand_sol(V,C)
    rd_sol = [1:C, zeros(1,V)];
    [~,n] = size(rd_sol);
    idx = randperm(n);
    b = zeros(1,C+V);
    b(1,idx) = rd_sol(1,:);
    rd_sol = b;
    r2=rd_sol;
end

%Function to generate random routes for each vehicle
function r3 = rand_route_sol(rd_sol, C, V)
    rd_route = zeros(1,(2*C + V)); %route matrix, vehicles separated with 0
    rd_idx = 1; %index for matrix
    rd_sol_idx = 1; %index for input matrix
    for i=1:(V+1)  %go through for each Vehicle
        if(rd_sol_idx > (V + C))
            break;
        end
        call = rd_sol(1,rd_sol_idx);
        rd_sol_idx = rd_sol_idx + 1;
        rd_route(1,rd_idx) = call; %first call/zero will always be first
        rd_idx = rd_idx +1; %for each vehicle
        if(call == 0) %continue for loop if call is 0
             %skipping a 0 to indicate next vehicle
            continue;
        end
        
        opt_calls = zeros(1,C); %possible options of delivery/pickups
        opt_idx = 1;    %index for the possible options
        opt_calls(1,opt_idx) = call; %adding delivery of call as an option

        if(rd_sol_idx <= (C+V))
            call = rd_sol(1,rd_sol_idx); %next call
            rd_sol_idx = rd_sol_idx +1;
        else
            call = 0;
        end
        
        if(call == 0) %if second call is 0, add delivery to route and move
            rd_route(1,rd_idx) = rd_route(1,rd_idx -1); %on to next vehicle
            rd_idx = rd_idx +2; %skipping a 0 to indicate next vehicle
            continue;
        end
        
        %if not i will have more than one call and i have to ch0ose a random
        %option to either pickup new call or deliver the first call
        %adding delivery of first call as  
        opt_idx = opt_idx + 1;    
        opt_calls(1,opt_idx) = call; %pickup of next call is also an option

        
        %starting iteration of choosing options
        while(opt_idx > 0)
            
            
            %if a new call is being picked up there will be a new
            %option added to the matrix, i.e. either deliver picked up
            %calls or pick up a new option
            %if a call is being delivered i have to remove the delivered
            % call from options, this way there will always be an option to
            % pick up a new call if one exists even if all other calls are
            % delivered
            chosen_opt_idx = randi([1,opt_idx],1,1); %generating a random 
            chosen_opt = opt_calls(1,chosen_opt_idx); %index from options
            
            rd_route(1,rd_idx) = chosen_opt; %adding choice to output vector
            rd_idx = rd_idx + 1;    %updating index of output vector
            
            if(chosen_opt == call) %if i chose to pick up next call 
                if(rd_sol_idx <= (C + V)) %if i am not on the last pickup
                    call = rd_sol(1,rd_sol_idx); %call to pick up
                    rd_sol_idx = rd_sol_idx +1;
                    if(call ~= 0) %if call belongs to same vehicle i will
                        opt_idx = opt_idx + 1;  %add the pickup of the next call after                
                        opt_calls(1,opt_idx) = call;  %the optional delivery calls
                    end
                else %if i am on the last pickup i will do nothing with the 
                    call = 0; %and only change the call to a non option 
                end %element
                %and again choose a random option to deliver
            else %if i chose to deliver a call i have to remove that option                
                b = opt_calls'; %from the options call vector
                b(chosen_opt_idx) = [];
                opt_calls = b';
                opt_idx = opt_idx -1;
            end       
        end
        rd_idx = rd_idx +1; %skipping a 0 to idicate next vehicle
    end
    r3 = rd_route;
end
%__________________________________________________________________________

%__________________________________________________________________________
%FEASIBILITY CHECK 1
%function for first feasibility check, is each call possible with the 
%assigned vehicle;
function f4 = feas_check1(rd_sol, veh_call, C, V)
    feasible = 1;
    veh = 1;
    for i=1:(C+V)
        if(veh >= 6)
            break;
        end
        call = rd_sol(1,i);
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
function f2 = feas_check2(rd_route, vehicle_spec, call_spec, C, V)
    picked_up_calls = zeros(C,1); %boolean table to keep track of if a call 
    feasible = 1; %is being picked up or delivered.
    v = 1; %starting on vehicle 1
    veh_load = 0;
    load_cap = vehicle_spec(v,4);
    for i =1:(V+2*C) %going through each element in the rd_route

        call = rd_route(1,i);
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

function f3 = feas_check3(rd_route, vehicle_spec, call_spec, route_spec, load_spec, C, V, N)
    feasible3 = 1;
    picked_up_calls = zeros(C,1); %boolean table to keep track of if a call
            %is being picked up or delivered
    v = 1;
    veh_location = vehicle_spec(v,2);
    veh_t = vehicle_spec(v,3);
    for i=1:(V+C*2)
        %setting the location of the vehicle to the start and the time to
        %the starting time of the vehicle.
        call = rd_route(1,i);
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

function o = obj_func(rd_route, vehicle_spec, route_spec, call_spec, load_spec, V, C, N)
    sol_c = 0;
    picked_up_calls = zeros(C,1);
    veh = 1; %setting start location for first vehicle
    veh_loc = vehicle_spec(veh,2);
    idx = 0;
    for j=1:(2*C + V)
        call = rd_route(1, j);        
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
        call = rd_route(1, idx); %route of dummy vehicle or 0
        sol_c = sol_c + call_spec(call,5); %adding cost of not picking up
        idx = idx +2; %skipping the delivery index
    end
    o = sol_c;
end
%__________________________________________________________________________
%END OF FUNCTIONS SECTION
%__________________________________________________________________________
