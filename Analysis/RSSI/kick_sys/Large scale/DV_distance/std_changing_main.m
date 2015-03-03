close all; clear all; clc;
rng default;

start_point = 0.05;
end_point = 0.50;
num_trials = 10;
error_matrix=[];
aggregate_error_matrix=[];
connectivity_array=[];
coverage_matrix = [];

for i=start_point:0.05:end_point % number of nodes
    aggregate_error=[];
    aggregate_connectivity_counter=0;
    aggregate_coverage = 0;
    for j=1:num_trials % number of trials
        [average_loc_error_array,coverage,avg_connectivity] = main(100,i,0.2);
        aggregate_error=[aggregate_error;average_loc_error_array];
        aggregate_connectivity_counter = aggregate_connectivity_counter + avg_connectivity;
        aggregate_coverage = aggregate_coverage + coverage;
    end
    aggregate_error_matrix = [aggregate_error_matrix;aggregate_error];
    error_matrix = [error_matrix;mean(aggregate_error)];
    connectivity_array = [connectivity_array aggregate_connectivity_counter/num_trials];
    coverage_matrix = [coverage_matrix aggregate_coverage/num_trials];
end

error_matrix = error_matrix';

save std_0.05_to_0.5.mat;

figure;
x = start_point:0.05:end_point;
plot(x,error_matrix,'*-');
xlabel('Measurement error Std');
ylabel('Relative error') ;
legend('kick','DV-distance','N-hop-lateration');