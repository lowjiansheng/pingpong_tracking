file_path_vid = "./TestVideos/";
mp4 = ".mp4";
file_path_annot = "./Annotation/";
csv = ".csv";

% Store where all the files are
files_angle1 = ["CAM1-GOPR0333-21157", "CAM1-GOPR0333-25390", "CAM1-GOPR0333-28114", "CAM1-GOPR0333-31464", "CAM1-GOPR0333-34217", "CAM1-GOPR0334-6600", "CAM1-GOPR0334-14238", "CAM1-GOPR0334-16875", "CAM1-GOPR0334-26813", "CAM1-GOPR0334-36441"];
files_angle2 = ["CAM2-GOPR0288-21180", "CAM2-GOPR0288-25413", "CAM2-GOPR0288-28137", "CAM2-GOPR0288-31487", "CAM2-GOPR0288-34240", "CAM2-GOPR0289-6563", "CAM2-GOPR0289-14201", "CAM2-GOPR0289-16838", "CAM2-GOPR0289-26776", "CAM2-GOPR0289-36404"];
files_angle3 = ["CAM3-GOPR0342-21108", "CAM3-GOPR0342-25341", "CAM3-GOPR0342-28065", "CAM3-GOPR0342-31415", "CAM3-GOPR0342-34168", "CAM3-GOPR0343-6479", "CAM3-GOPR0343-14117", "CAM3-GOPR0343-16754", "CAM3-GOPR0343-26692", "CAM3-GOPR0343-36320"];

% Read in the video file (change this to read all files later)
pingpong = VideoReader(strcat(file_path_vid, files_angle1(2), mp4));

% read in as csv for easier processing
annotated_csv = csvread(strcat(file_path_annot, files_angle1(2), csv), 1, 0);

% Get background of video
% We do so by averaging away the foreground (moving objects)

% Firstly, we create a new matrix to store the color values of each pixel
background = struct('cdata',zeros(pingpong.Height,pingpong.Width,3,'uint8'),'colormap',[]);
mov = struct('cdata', zeros(pingpong.Height,pingpong.Width,3,'uint8'), 'colormap', []);

% Then we iterate through each frame (and all pixels) so that we get a
% running average as given by the formula in L5Color#33
k = 1;
while hasFrame(pingpong)
    mov(k).cdata = readFrame(pingpong);
    background.cdata = ((k-1)/k) .* background.cdata + (1/k) .* mov(k).cdata;
    k = k + 1;
end
num_frames = k - 1;

% extract foreground from every frame, change image into greyscale, store
% the new matrix into matrix called foreground
foreground = rgb2gray(mov(1).cdata - background.cdata);
for frame = 2:num_frames
    foreground(:,:,frame) = rgb2gray(mov(frame).cdata - background.cdata);
end
num_rows = size(foreground, 1);
num_columns = size(foreground, 2);

%{
% We keep a count of each pixel intensity so that we can find the xth
% percentile to set a threshold
pixel_intensity_count = zeros(1, 256);
for frame = 1:num_frames
    for i = 1:num_rows
        for j = 1:num_columns
            pixel_value = foreground(i, j, frame);
            % because matlab is zero idx
            pixel_intensity_count(pixel_value + 1) =  pixel_intensity_count(pixel_value + 1) + 1;
        end
    end
end

%{
identify threshold by using percentile of pixel intensity counts
we identify threshold from all frames because there are certain frames
whereby there is no ball- we do not want false positives in those cases

we set the threshold to be a lower percentile for now as my theory is that
there exists a large number of dark pixels in frames without ball
%}
running_sum = zeros(1, 256);
running_sum(1) = pixel_intensity_count(1);
for i = 2:256
    running_sum(i) = running_sum(i-1) + pixel_intensity_count(i);
end


% Trying to find a threshold_intensity by using percentile
percentile = 75;
threshold_count = prctile(running_sum, percentile);
threshold_intensity = -1; % dummy value
for i = 1:256
    if running_sum(i) >= threshold_count
        threshold_intensity = i;
        break;
    end
end
assert(threshold_intensity ~= -1)
%}

% Hard threshold by manual selection
threshold_intensity_arr = [150, 0, 0];
threshold_intensity = 147;

% create array to store our coordinates of ball from feature tracker
tracked_arr = zeros(num_frames, 3); 
max_possible_num_of_pixels = num_rows * num_columns; % check - not rigorous
% max_possible_num_of_frames = ceil((100 - percentile) / 100 * num_rows * num_columns);
num_empty_frames = 0; % to check
% collate info of all pixels that will has an intensity >= threshold
for frame = 1:size(foreground, 3)
    tracked_arr(frame, 1) = frame;
    x_coord = zeros(1, max_possible_num_of_pixels);
    y_coord = zeros(1, max_possible_num_of_pixels);
    above_count = 0;
    % we change the search region from the original whole window to the
    % frame that contains the table as denoted by
    % i from 200 to 600
    % and j from 350 to 1650
    for i = 200:600
        for j = 350:1650
            if foreground(i,j,frame) >= threshold_intensity
                above_count = above_count + 1;
                x_coord(above_count) = i;
                y_coord(above_count) = j;
            end
        end
    end
    if above_count == 0
        % no coordinates to fill in, go to next frame
        tracked_arr(frame, 2) = 0;
        tracked_arr(frame, 3) = 0;
        num_empty_frames = num_empty_frames + 1;
        continue;
    end
    x_coord_sum = 0;
    y_coord_sum = 0;
    for i = 1:above_count
        x_coord_sum = x_coord_sum + x_coord(i);
        y_coord_sum = y_coord_sum + y_coord(i);
    end
    % no particular reason if we should use floor or ceiling here
    x_centroid_pos = ceil(x_coord_sum / above_count);
    y_centroid_pos = ceil(y_coord_sum / above_count);
    % write x_centroid_pos and y_centroid_pos to the array
    % there are some bugs with swapping rows and columns
    tracked_arr(frame, 2) = y_centroid_pos;
    tracked_arr(frame, 3) = x_centroid_pos;
end
            
disp("The number of empty frames is: ");
disp(num_empty_frames);

% calculate 3 main variables:
% 1. points we annotated when there was no ball (wrong ball)
% 2. points we didn't annotate when there was a ball (missed ball)
% 3. average euclidean distance of the errors (when we identified a ball
% and there is indeed a ball)
num_wrong_ball = 0;
num_missed_ball = 0;
sum_euclidean_dist = 0;
num_correct_frames_marked = 0;
num_correct_frames_unmarked = 0;
for frame = 1:size(annotated_csv,1)
    if ((annotated_csv(frame, 2) == 0) && (annotated_csv(frame,3) == 0) && (tracked_arr(frame, 2) ~= 0) && (tracked_arr(frame,3) ~= 0))
        num_wrong_ball = num_wrong_ball + 1;
    elseif (annotated_csv(frame, 2) ~= 0) && (annotated_csv(frame,3) ~= 0) && (tracked_arr(frame, 2) == 0) && (tracked_arr(frame,3) == 0)
        num_missed_ball = num_missed_ball + 1;
    elseif (annotated_csv(frame, 2) == 0) && (annotated_csv(frame,3) == 0) && (tracked_arr(frame, 2) == 0) && (tracked_arr(frame,3) == 0)
        num_correct_frames_unmarked = num_correct_frames_unmarked + 1;
    else
        sum_euclidean_dist = sum_euclidean_dist + sqrt((annotated_csv(frame,2) - tracked_arr(frame,2))^2 + (annotated_csv(frame,3) - tracked_arr(frame,3))^2);
        num_correct_frames_marked = num_correct_frames_marked + 1;
    end
end

disp(num_wrong_ball);
disp(num_missed_ball);
disp(num_correct_frames_unmarked);
disp(num_correct_frames_marked);
disp(sum_euclidean_dist / num_correct_frames_marked);