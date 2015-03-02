%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  DV-distance algorithm
% 
%  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DV_distance
    global Length;
    global Width;
    global NUM_NODE;
    global Node;
    global BEACON_RATIO;
    global STAGE_NUMBER;
    
    % set nodes est coordinates, time scheduling
    for i=1:NUM_NODE
        Node(i).sched=rand;    % time scheduling of the system, set to random
        Node(i).correction=0;   % intiailize the correction to be 0

        if (i <= round(NUM_NODE*BEACON_RATIO)) % beacon
            Node(i).est_pos = Node(i).pos;
            Node(i).dv_vector=[Node(i).id 0];  % initialize accessible dv vector, itself.
        else                            % unknown
            Node(i).est_pos = [Width*0.5;Length*0.5]; % set initial est_pos at center.
            Node(i).dv_vector=[];  % initialize accessible dv vector to none
        end
    end

    % sort the time schedule of all the nodes
    tmp_sched = [];
    for i=1:NUM_NODE
        tmp_sched = [tmp_sched;[Node(i).sched Node(i).id]];
    end
    tmp_sched = sortrows(tmp_sched);
    sched_array = tmp_sched(:,2)';
    
    %the system runs 
    for time = 0:STAGE_NUMBER
        for index = sched_array
            Node(index) = broadcast(Node(index));
        end
    end

    %Phase 2: Node position - lateration
    for i= round(NUM_NODE*BEACON_RATIO)+1:NUM_NODE
        beacon_list = Node(i).dv_vector(:,1)';
        if length(beacon_list)>2
            Node(i) = lateration(Node(i));
        end
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sub-function, node A broadcasts to its neighbors its current distance
% to all the beacons it can reach.
function  A = broadcast(A)
    global Node;
    global WGN_DIST;
    % if beacon has no correction yet and has access to other beacon, then
    % calculate a correction.
    if A.correction == 0 && strcmp(A.attri,'beacon')  && size(A.dv_vector,1)>1
        tmp_id = A.dv_vector(2,1);
        A.correction = A.dv_vector(2,2)/DIST(A,Node(tmp_id)); 
    end
    
    % if A has beacon dv_vector to broadcast
    if ~isempty(A.dv_vector)
        beacon_list = A.dv_vector(:,1)';
        % iterate all neighbors
        for neighbor_index = A.neighbor
            %  if A has correction, and the neighbor doesn't have it,
            %  forward the correction.
            if A.correction ~= 0 && Node(neighbor_index).correction == 0
                Node(neighbor_index).correction = A.correction;
            end
            
            for beacon_index = beacon_list
                % if beacon not in neighbor's talbe, add directly
                if isempty(Node(neighbor_index).dv_vector) 
                    beacon_node_dist = A.dv_vector(find(A.dv_vector(:,1)==beacon_index),2); 
                    beacon_neighbor_dist = beacon_node_dist + WGN_DIST(A.id,Node(neighbor_index).id);
                    Node(neighbor_index).dv_vector = [Node(neighbor_index).dv_vector; beacon_index beacon_neighbor_dist];
                elseif ~ismember(beacon_index,Node(neighbor_index).dv_vector(:,1))
                    beacon_node_dist = A.dv_vector(find(A.dv_vector(:,1)==beacon_index),2); 
                    beacon_neighbor_dist = beacon_node_dist + WGN_DIST(A.id,Node(neighbor_index).id);
                    Node(neighbor_index).dv_vector = [Node(neighbor_index).dv_vector; beacon_index beacon_neighbor_dist];
                % if beacon is already in neighbor's table, compare and
                % update accordingly.
                else
                    beacon_neighbor_dist = Node(neighbor_index).dv_vector(find(Node(neighbor_index).dv_vector(:,1)==beacon_index),2);
                    beacon_node_dist = A.dv_vector(find(A.dv_vector(:,1)==beacon_index),2); 
                    if beacon_neighbor_dist > beacon_node_dist + WGN_DIST(A.id,Node(neighbor_index).id)
                        Node(neighbor_index).dv_vector(find(Node(neighbor_index).dv_vector(:,1)==beacon_index),2)   = beacon_node_dist + WGN_DIST(A.id,Node(neighbor_index).id);
                    end  
                end
            end
        end
    end
end
                

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sub-function, node U calulate its own position using least-square lateration.
function U = lateration(U)
    global Node;
    % initialize matrix A and b.
    A=[];
    b=[];
    beacon_list = U.dv_vector(:,1)';
    n= beacon_list(end); % the last beacon 
    
    tmp_dv_vector = U.dv_vector(:,2)';
    %{
    % use correction to correct the distance_vector
    if U.correction ~= 0
        tmp_dv_vector = tmp_dv_vector/U.correction;
    end
    %}
    
    counter = 0; % counter for sequence to access dv_vector
    
    for beacon_index = beacon_list
        counter = counter + 1;
        if beacon_index ~= n
            A=[A;2*(Node(beacon_index).pos(1)-Node(n).pos(1)) 2*(Node(beacon_index).pos(2)-Node(n).pos(2))];
            b=[b;(Node(beacon_index).pos(1))^2 - (Node(n).pos(1))^2 + (Node(beacon_index).pos(2))^2 - (Node(n).pos(2))^2 + tmp_dv_vector(size(tmp_dv_vector,2))^2 - tmp_dv_vector(counter)^2
];
        end
    end
    % solve the system using least-square
    U.est_pos = (transpose(A)*A)^(-1)*transpose(A)*b;
end
    




