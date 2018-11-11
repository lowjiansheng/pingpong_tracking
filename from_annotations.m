FileList = readtable("FileList.csv", 'ReadRowNames', false, 'ReadVariableNames', false);
FileList = FileList{:,:};

% Extrinsics
camera1_Rs = [9.6428667991264605e-01 -2.6484969138677328e-01 -2.4165916859785336e-03;
-8.9795446022112396e-02 -3.1832382771611223e-01 -9.4371961862719200e-01;
2.4917459103354755e-01 9.1023325674273947e-01 -3.3073772313234923e-01];

camera2_Rs = [9.4962278945631540e-01 3.1338395965783683e-01 -2.6554800661627576e-03;
1.1546856489995427e-01 -3.5774736713426591e-01 -9.2665194751235791e-01;
-2.9134784753821596e-01 8.7966318277945221e-01 -3.7591104878304971e-01];

camera3_Rs = [-9.9541881789113029e-01 3.8473906154401757e-02 -8.7527912881817604e-02;
9.1201836523849486e-02 6.5687400820094410e-01 -7.4846426926387233e-01;
2.8698466908561492e-02 -7.5301812454631367e-01 -6.5737363964632056e-01];

camera1_ts= -inv(camera1_Rs)*[1.3305621037591506e-01;
-2.5319578738559911e-01;
2.2444637695699150e+00];

camera2_ts= -inv(camera2_Rs)*[-4.2633372670025989e-02;
-3.5441906393933242e-01;
2.2750378317324982e+00];

camera3_ts= -inv(camera3_Rs)*[-6.0451734755080713e-02;
-3.9533167111966377e-01;
2.2979640654841407e+00];

cameras_Rs = cat(3, camera1_Rs, camera2_Rs, camera3_Rs);
cameras_ts = cat(3, camera1_ts, camera2_ts, camera3_ts);

% There shouldn't be a need to use the intrinsic parameters since we will
% be using the undistorted coordinates

cameras = cell(1, 3);
for camera_index=1:3
    cameras{camera_index} = Camera(cameras_Rs(:,:,camera_index), cameras_ts(:,:,camera_index));
end

% No change in coordinate system yet
new_coord_system = [ 1 0 0; 0 1 0; 0 0 1]

% figure % Uncomment if want new figure for every run else reuse figure 
for camera_index=1:3    
    cameras{camera_index}.changeCoordinateSystem(new_coord_system');
    camera_plot = num2cell(cameras{camera_index}.getOpticalAxisPlotCoordinates(), 1);
    plot3(camera_plot{:}, 'b')
    hold on
    
    camera_plot = num2cell(cameras{camera_index}.getVerticalAxisPlotCoordinates(), 1);
    plot3(camera_plot{:}, 'g')
    
    camera_plot = num2cell(cameras{camera_index}.getHorizontalAxisPlotCoordinates(), 1);
    plot3(camera_plot{:}, 'r')
    text(cameras{camera_index}.position(1), cameras{camera_index}.position(2), cameras{camera_index}.position(3), strcat('cam',int2str(camera_index)))
end
grid on
hold off
% camera2_plot = num2cell(cameras{2}.getPlotCoordinates(), 1);
% camera3_plot = num2cell(cameras{3}.getPlotCoordinates(), 1);

% plot3(camera1_plot{:})
% hold on
% plot3(camera2_plot{:})
% plot3(camera3_plot{:})
% hold off
xlabel('x')
ylabel('y')
zlabel('z')

for trajectory_index=1:size(FileList,1)
%     Each row represents a trajectory.
%     col is the coordinates of the ball from a camera
    coords_tables = cell(1, size(FileList,2));
    for camera_index=1:size(FileList,2)
        coords_filename = strcat('Annotation/', strrep(FileList{trajectory_index, camera_index}, 'mp4', 'csv'));
        coords_table = readtable(coords_filename, 'ReadVariableNames', true);
        coords_tables{camera_index} = coords_table;
    end
    
%     Do the fancy shitzos here
%     get3DCoordinates()

    
end