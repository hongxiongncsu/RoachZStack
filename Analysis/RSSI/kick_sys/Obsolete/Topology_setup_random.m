close all; clear all; clc;
% Localization initialization
Length=40; % area space, unit: meter
Width=40;  % area space, unit: meter
global NUM_NODE;
NUM_NODE=6; % number of total nodes
beacon_ratio=0.5; 
TRANS_RANGE=20;       % transmission range 20 meters
global STAGE_NUMBER;
STAGE_NUMBER=20;      % number of stages
global STD_INITIAL;
STD_INITIAL = 10000;   % initial std for unknown
global Node;
% set nodes coordinates, est coordinates, attribute,time scheduling and 
% intial std
for i=1:NUM_NODE
    Node(i).x = Width*rand;
    Node(i).y = Length*rand; 
    Node(i).id = i;         % node ID
    Node(i).sched=rand;    % time scheduling of the system, set to random
    if (i <= NUM_NODE*beacon_ratio) % beacon
        Node(i).est_x=Node(i).x; 
        Node(i).est_y=Node(i).y;
        Node(i).std=0;
        Node(i).attri = 'beacon';
    else                            % unknown
        Node(i).est_x=0; 
        Node(i).est_y=0;
        Node(i).std=STD_INITIAL;
        Node(i).attri = 'unknown';
    end
end

%{
% Example topology
Node(1).pos = [6.84192070101789;37.5423145732737];
Node(1).est_pos = Node(1).pos;
Node(2).pos = [17.6253872304336;37.6767572124513];
Node(2).est_pos = Node(2).pos;
Node(3).pos = [18.0778283704154;33.5878968287868];
Node(3).est_pos = Node(3).pos;
Node(4).pos = [22.1554826316510;27.2026212033344];
Node(5).pos = [9.57162424774182;23.1569396983637];
Node(6).pos = [16.2710704086090;4.50460564100187];
%}

% take a look at the generated topology
figure
hold on;box on;axis([0 Length 0 Width]); %the frame of the plot
 for i=1:NUM_NODE
    h1=plot(Node(i).x,Node(i).y,'ko','MarkerFace','g','MarkerSize',10);
    text(Node(i).x+3,Node(i).y,strcat('Node',num2str(i)));
 end
 
%calculate neighbor array
for i=1:NUM_NODE
    Node(i).neighbor = []; %initialize the neighbor array
    tmp_array = [1:NUM_NODE];
    tmp_array(tmp_array==i)=[]; % delete node i itself
    for j=tmp_array
        if DIST(Node(i),Node(j))<=TRANS_RANGE
            Node(i).neighbor = [Node(i).neighbor j];
            % draw a line between neighbor nodes on the plot
            line([Node(i).x,Node(j).x],[Node(i).y,Node(j).y],'Color','k'); 
        end
    end
end

kick_loc_random;

