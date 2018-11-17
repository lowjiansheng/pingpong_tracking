function showCameras(cameras,to_hold_or_not_to_hold)
%SHOWCAMERA Summary of this function goes here
%   Detailed explanation goes here
for camera_index=1:size(cameras,2)
    camera_plot = num2cell(cameras{camera_index}.getOpticalAxisPlotCoordinates(), 1);
    plot3(camera_plot{:}, 'b')
    if to_hold_or_not_to_hold
        hold on
    end

    camera_plot = num2cell(cameras{camera_index}.getVerticalAxisPlotCoordinates(), 1);
    plot3(camera_plot{:}, 'g')
    
    camera_plot = num2cell(cameras{camera_index}.getHorizontalAxisPlotCoordinates(), 1);
    plot3(camera_plot{:}, 'r')
    text(cameras{camera_index}.position(1),...
        cameras{camera_index}.position(2),...
        cameras{camera_index}.position(3),...
        strcat('cam',int2str(camera_index)))
end

grid on
xlabel('x-table-length')
ylabel('y-table-width')
zlabel('z-table-height')
end

