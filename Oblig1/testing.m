%with this function:
function g = make_graph(best_sol, vehicle_spec)
    v = 1; %first vehicle
    node_v = vehicle_spec(v,2);
    node = 1;
    s_idx = 1;

    for i=1:(2*C+V)
     call = best_sol(1,i);
        if(call == 0)
            v = v+1;
            node_v = vehicle_spec(v,2);
            continue;
        end
        s(s_idx) = node;
        w(s_idx) = v;
        names{node} = ['H' num2str(v)];
        node = node +1;
        
        
    
    
    
    
    end
    g = digraph(s,t,w,names);

end


%Test section
pos_solution = [12  4  12  4  3  3  0 15  5  5  15  1  17  17  1  0 11  16  16  11  10  9  10  9  0 6  6  8  7  8  7  2  2  0 18  14  18  14  0 13  13]

feas_check1(pos_solution, veh_call, C,V)

feas_check2(pos_solution, vehicle_spec, call_spec, C, V)

feas_check3(pos_solution, vehicle_spec, call_spec, route_spec, load_spec, C, V, N)

obj_func(pos_solution, vehicle_spec, route_spec, call_spec, load_spec, V, C, N) 