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

% Intrinsics
cam1_cal_mat = [8.7014531487461625e+02 0 9.4942001822880479e+02;
                0 8.7014531487461625e+02 4.8720049852775117e+02;
                0 0 1];
cam2_cal_mat = [8.9334367240024267e+02 0 9.4996816131377727e+02;
                0 8.9334367240024267e+02 5.4679562177577259e+02;
                0 0 1];
cam3_cal_mat = [8.7290852997159800e+02 0 9.4445161471037636e+02;
                0 8.7290852997159800e+02 5.6447334036925656e+02;
                0 0 1];
cams_cal_mat = cat(3, cam1_cal_mat, cam2_cal_mat, cam3_cal_mat);

cameras = cell(1, 3);
for camera_index=1:3
    cameras{camera_index} = Camera(cameras_Rs(:,:,camera_index), cameras_ts(:,:,camera_index));
    cameras{camera_index}.setCalibrationMatrix(cams_cal_mat(:,:,camera_index));
end

% No change in coordinate system yet
new_coord_system = [ 1 0 0; 0 1 0; 0 0 1];

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
    text(cameras{camera_index}.position(1),...
        cameras{camera_index}.position(2),...
        cameras{camera_index}.position(3),...
        strcat('cam',int2str(camera_index)))
end
grid on


for traj_index=1:size(FileList,1)
%     Each row represents a trajectory.
%     col is the coordinates of the ball from a camera
    coords_tables = cell(1, size(FileList,2));
    for camera_index=1:size(FileList,2)
        coords_filename = strcat('Annotation/',...
            strrep(FileList{traj_index, camera_index}, 'mp4', 'csv'));
        opts = setvartype(detectImportOptions(coords_filename),...
            {'x','y','undistort_x','undistort_y'},'double');
        coords_table = readtable(coords_filename, opts);
        coords_tables{camera_index} = coords_table;
    end
    
%     Do the fancy shitzos here
    trajs = Estimate3DCoordinates(cameras{1}, ...
                        cameras{2}, ...
                        cameras{3}, ...
                        coords_tables{1}{:,{'undistort_x', 'undistort_y'}}, ...
                        coords_tables{2}{:,{'undistort_x', 'undistort_y'}}, ...
                        coords_tables{3}{:,{'undistort_x', 'undistort_y'}});
    traj_1 = trajs(:,:,1);
    traj_2 = trajs(:,:,2);
    traj_3 = trajs(:,:,3);
    traj_4 = trajs(:,:,4);
    
    traj_4 = cat(2, coords_tables{1}{:,{'undistort_x', 'undistort_y'}}* 0.001, zeros(size(traj_1,1), 1)+ 0.1);
    
    traj_table = array2table(traj);
%     Visualize3DMat(traj_4, 'r')
%     traj_plot1 = num2cell(traj_1, 1);
%     traj_plot2 = num2cell(traj_2, 1);    
%     traj_plot3 = num2cell(traj_3, 1);   
%     traj_plot4 = num2cell(traj_4, 1);
%     
%     plot3(traj_plot1{:}, 'r');    
%     plot3(traj_plot2{:}, 'g');
%     plot3(traj_plot3{:}, 'b');
%     plot3(traj_plot4{:}, 'y');
%     
    traj_table.Properties.VariableNames = {'x', 'y', 'z'};
    writetable(traj_table, strcat('trajectory_', int2str(traj_index), '.csv'));
    break
end

hold off