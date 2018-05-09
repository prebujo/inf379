ini = [1,1,0,5,5,0,3,3,0,4,4,2,2,6,6,7,7]
ini=insert(4,1,1,ini,veh_call, vehicle_spec, call_spec, route_spec,load_spec, V,C,N)
ini=insert(6,1,1,ini,veh_call, vehicle_spec, call_spec, route_spec,load_spec, V,C,N)
ini=insert(2,8,2,ini,veh_call, vehicle_spec, call_spec, route_spec,load_spec, V,C,N)
ini=insert(7,13,3,ini,veh_call, vehicle_spec, call_spec, route_spec,load_spec, V,C,N)

function r = remove(call,ini_sol, V, C)
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

function i = insert(call, idx, veh, ini_sol, veh_call, veh_spec, call_spec, route_spec, load_spec, V,C,N)
old_call = call;
new_sol = ini_sol;
new_idx = idx;
if(ismember(call,veh_call(veh,2:C+1)))
    
    %time, stating node and cap of vehicle
    veh_t = veh_spec(veh,3);
    veh_n = veh_spec(veh,2);
    veh_cap = veh_spec(veh,4);
    
    %variables for the given input call
    call_ub_tw = call_spec(call, 7);
    call_lb_tw = call_spec(call, 6);
    call_size = call_spec(call, 4);
    ch_count = 1; %how many choices I currently have
    
    %initializing initial solution call if vehicle has one
    ini_call = ini_sol(1,idx);    
    if(ini_call ~=0) 
        ch_count = ch_count+1;
        ini_ub_tw = call_spec(ini_call,7);
        ini_lb_tw = call_spec(ini_call,6);
        ini_size = call_spec(ini_call, 4);
    end
    
    %initializing boolean table to indicate pickup/delivery
    is_picked = zeros(1,C);
    
    while(ch_count>0)
        chosen = 0;
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
                ini_lb_tw = call_spec(ini_call,8);
                ini_size = call_spec(ini_call, 4);
            else
                ini_ub_tw = call_spec(ini_call,7);
                ini_lb_tw = call_spec(ini_call,6);
                ini_size = call_spec(ini_call, 4);
            end
        else %if I chose call update to delivery
            call_ub_tw = call_spec(call, 9);
            call_lb_tw = call_spec(call, 8);
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
    new_sol = 0;
end
i = new_sol;
end