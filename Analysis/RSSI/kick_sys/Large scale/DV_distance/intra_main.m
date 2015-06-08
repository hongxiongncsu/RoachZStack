function [loc_error_kick, loc_error_kick_kalman, loc_error_kick_kalman_2nodes,connectivity_counter,coverage] = intra_main(num_node,dis_std_ratio,beacon_ratio)
    if nargin < 3
        disp('Please give num_node,dis_std_ratio,beacon_ratio');
        return;
    end
    %close all; clear all; clc;
    %rng default;
    %rng (6);
    % Configure topology-related parameters
    Topology_setup_no_CRLB;
    [loc_error_kick,coverage_KI] = kick_loc;
    [loc_error_kick_kalman,coverage_KK] = kick_loc_kalman;
    %[average_loc_error_kick_kalman_remove,confidence_interval] = kick_loc_kalman_remove;
    [loc_error_kick_kalman_2nodes,coverage_KK2]=kick_loc_kalman_2nodes;
    coverage = [coverage_KI coverage_KK coverage_KK2];
    %[average_loc_error_kick_loc_kalman_2nodes_remove,confidence_interval]=kick_loc_kalman_2nodes_remove;
    %[average_loc_error_kick_loc_kalman_change_var,confidence_interval]=kick_loc_kalman_change_var;
    %average_loc_error_array = [average_loc_error_kick average_loc_error_kick_kalman ...
    %   average_loc_error_kick_kalman_remove average_loc_error_kick_loc_kalman_2nodes average_loc_error_kick_loc_kalman_2nodes_remove average_loc_error_kick_loc_kalman_change_var];
    %average_loc_error_array = [average_loc_error_kick average_loc_error_kick_kalman average_loc_error_kick_kalman_2nodes];
end