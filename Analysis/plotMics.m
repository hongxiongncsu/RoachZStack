clear all;
close all;

port = serial('COM7','BaudRate',115200, 'FlowControl', 'hardware');
fopen(port);

signal = [255, 255, 255, 255, 255, 255];
buffer = zeros(1, length(signal));
while (1)
    data = fread(port, 1, 'uint8')';
    buffer = [data(1), buffer(1:end-1)]
    if signal==buffer
        break;
    end
end

size = 33;
channels = 3
data = zeros(channels,size);
ah = zeros(1, channels);
for channel = 1:channels
    ah(channel) = subplot(3,1,channel);
end
%figure; hold on;

plotSamples = 30;
plotBuffer = zeros(channels,plotSamples);
index = 1;
while (1)
    newData = fread(port, size, 'int16')';
    newData=reshape(newData, 3, length(newData)/3);
    for channel = 1:channels
        plotBuffer(channel,index:index+length(newData)-2) = newData(channel,1:length(newData)-1)
        %axes(ah(channel));
        %cla;
        %plot(newData(channel,:));
        %ylim([0, 8191])
    end
    index = index + length(newData)-1;
    if index == plotSamples + 1
        index = 1;
        for channel = 1:channels
            axes(ah(channel));
            cla;
            plot(plotBuffer(channel,:));
            ylim([0, 8191])
        end
        drawnow;
        refresh;
    end
    %drawnow;
    %refresh;
end


% while (1)
%     for channel = 1:channels
%         newData = fread(port, 1, 'int16')';
%         if newData == 65535
%             break;
%         end
%         data(channel,:) = [newData data(channel,1:end-1)];
%         axes(ah(channel));
%         cla;
%         plot(data(channel,:));
%         ylim([0, 8191])
%     end
%     drawnow;
%     refresh;
% end
fclose(port);