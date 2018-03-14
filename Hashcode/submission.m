


%import data section
%______________________________________________________________________

fileID = fopen('/home/preben/Downloads/e_high_bonus.in');
%taking first input
inp_form = '%d%d%d%d%d%d\n';

input = fscanf(fileID, inp_form,[6,1]);
R = input(1,1);
C = input(2,1);
F = input(3,1);
N = input(4,1);
B = input(5,1);
T = input(6,1);

rides=zeros(N,6);

for i=1:N
    rides(i,:) = fscanf(fileID, inp_form, [1,6]); 
end

fclose(fileID);

M = 100;

best_sol = -1;
best_sol_rides = zeros(F+1,N);

for i=1:M
    rng shuffle;    
    rd_sol = randi(F+1,N,1);
    
    rd_calls = zeros(F+1,N);
    veh_index = zeros(F+1,1);
    for k=1:N
        veh = rd_sol(k,1);
        rd_calls(veh, (veh_index(veh,1)+1)) = k;
        veh_index(veh,1) = veh_index(veh,1)+1;
    end
    [m,n] = size(rd_calls);
    b=rd_calls;
    for h=1:m  %randomizing pickup/delivery schedule
        idx = randperm(n);
        b(h,idx) = rd_calls(h,:);  % b is a randomized version of rd_calls
    end
    veh_index = zeros(F+1,1); %resetting index vector
    for h=1:m   %arranging values left in the matrix again
        for k=1:n
            if(~(b(h,k) == 0))
                rd_calls(h,veh_index(h,1)+1) = b(h,k); %storing the left-
                %arranged values back in rd_calls
                veh_index(h,1) = veh_index(h,1) +1; %updating index
            end
        end
    end
    
    %calculation of solution
    sol = 0;
    for j =1:F
        t = 0;
        car = j;
        location = zeros(1,2);
        for k = 1:N           
            call = rd_calls(j,k);
            if(call == 0)
                continue
            end
            if(t>T) %if timelimit is exceeded i will continue to next car
                continue
            end
            pickup_loc = rides(call, 1:2);
            deliv_loc = rides(call, 3:4);
            pickup_time = rides(call, 5);
            deliv_time = rides(call, 6);
            
            pickup_t = abs(pickup_loc(1,1)-location(1,1)) + abs(pickup_loc(1,2)-location(1,2));
            
            t = t+pickup_t;
            if(t <= pickup_time) %assuming that pickup_time < T is always true
                t = pickup_time;
                sol = sol + 2;
            end
            
            deliv_t = abs(deliv_loc(1,1) - pickup_loc(1,1)) + abs (deliv_loc(1,2) - pickup_loc(1,2));
            t = t + deliv_t;
            if(t<deliv_time) %assuming that deliv_time < T is always true
                sol = sol + deliv_t;
            end
            location = deliv_loc;            
            
        end
        
    end
 
    if(sol>best_sol)
        best_sol = sol;
        best_sol_rides = rd_calls;
    end
end

    
%print solution section
fileID2 = fopen('/home/preben/Downloads/output.out','w'); %output file location
for i =1:F
    sumrides = nnz(best_sol_rides(i,:));
    fprintf(fileID2, '%d ', sumrides);
    
    
    for j=1:N
        outp = best_sol_rides(i,j);
        if(outp == 0)
            continue
        end
        fprintf(fileID2, '%d ', outp-1);
    end
    fprintf(fileID2, '\n');
end
fclose(fileID2);

