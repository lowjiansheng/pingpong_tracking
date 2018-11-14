% Overview of Lucas Kanade tracking + Harris corner detector
% 1. Use Harris corner detector to detect "good" features from the first
% frame.
% 2. Loop through the entire video, using LK tracker to track the good
% features.

% Reading the video file.
mulReader = VideoReader('vid1.mp4');
lenVideo = mulReader.Duration;
heightVideo = mulReader.Height;
widthVideo = mulReader.Width;
totalNumFrames = floor(lenVideo * mulReader.FrameRate);
% ball only appears after frame 10.

% Get background image
backgroundImage = uint8(zeros(heightVideo, widthVideo, 3));
curFrameNum = 1;
while hasFrame(mulReader)
    vidFrame = readFrame(mulReader);
    % vidFrame is a hxwx3 rgb array
    backgroundImage = ((curFrameNum - 1) / curFrameNum) * backgroundImage + (1 / curFrameNum) * vidFrame;
    curFrameNum = curFrameNum + 1;
end 
backgroundImage = round(backgroundImage);

% HARRIS CORNER DETECTOR. 
% Get top 50 corners only.
mulReader.CurrentTime = 0.15;
vidFrame = readFrame(mulReader);
pic_grey = double(rgb2gray(vidFrame - backgroundImage));

boundary = [500 100 500 900];
debugger = 0;
figH = figure;
imshow(pic_grey, [])
threshold_intensity = 147;
pos = [];
for i = 1:size(pic_grey,1)
    for j = 1:size(pic_grey,2)
        if pic_grey(i,j) >= threshold_intensity
            pos = [pos; i j];
            break;
        end
    end 
end
pos

for x = 1 : size(pos, 1)
    rectangle('Position', [pos(x,2) , pos(x,1), 13, 13], 'EdgeColor', 'r');
end

print(figH, '-djpeg', num2str(debugger));
pointTracker = vision.PointTracker('NumPyramidLevels', 6);
initialize(pointTracker, pos, pic_grey);

while hasFrame(mulReader)
    debugger = debugger + 1;
    figH = figure;
    if curFrameNum == totalNumFrames
        break
    end
    vidFrameNext = readFrame(mulReader);
    pic_grey_next = double(rgb2gray(vidFrameNext - backgroundImage));
    [points, validity] = pointTracker(pic_grey_next);
    points
    imshow(pic_grey_next, [])
    for x = 1 : size(pos, 1)
    %    if isnan(points(x,1)) || isnan(points(x,2))
    %        continue
    %    end
        rectangle('Position', [pos(x,2), pos(x,1), 13, 13], 'EdgeColor', 'r');
    end
    % break
    print(figH, '-djpeg', num2str(debugger));
end


while hasFrame(mulReader)
    break
    figH = figure;
    % Error at last frame trying to fetch last frame's next frame.
    if curFrameNum == totalNumFrames
        break
    end  
    vidFrameNext = readFrame(mulReader);
    pic_grey_next = double(rgb2gray(vidFrameNext - backgroundImage));
    [points, validity] = pointTracker(pic_grey_next);
    points
    % Loop through all the windows of the corners and find their next
    % position according to LK tracker.
     for x = 1 : size(pos_lowest_eig, 1)
        window_x = pos_lowest_eig(x, 1);
        window_y = pos_lowest_eig(x, 2);
        if isnan(window_x) || isnan(window_y)
            continue
        end
        if window_x + 6 > size(pic_grey, 2) || window_x - 6 < 0
           continue
        end
        if window_y + 6 > size(pic_grey, 1) || window_y - 6 < 0
            continue
        end
        initial_x = window_x - 6;
        initial_y = window_y + 6;
        % Calculating Z matrix
        neighbour_ix = Ix_matrix(initial_x : window_x + 6, initial_y : window_y + 6);
        neighbour_iy = Iy_matrix(initial_x : window_x + 6, initial_y : window_y + 6);
        ix_square = (neighbour_ix .* neighbour_ix);
        S_ix_square = sum(ix_square, 'all');
        ix_iy = (neighbour_ix .* neighbour_iy);
        S_ix_iy = sum(ix_iy, 'all');
        iy_square = (neighbour_iy .* neighbour_iy);
        S_iy_iy = sum(iy_square, 'all');
        Z = [S_ix_square S_ix_iy;
              S_ix_iy S_iy_iy];
          
        % Calculate b matrix. Will have to read the next frame.
        window_current_frame = pic_grey(initial_x : window_x + 6, initial_y : window_y + 6);
        window_next_frame = pic_grey_next(initial_x : window_x + 6, initial_y : window_y + 6);
        % size(window_current_frame - window_next_frame)
        % size(neighbour_ix)
        b = [sum((window_current_frame - window_next_frame) * neighbour_ix.', 'all');
                sum((window_current_frame - window_next_frame) * neighbour_iy.', 'all')];
        d_window = inv(Z) * b;
        % with dx, dy computed, will put in the new values into
        % pos_lowest_eig. 
        % note(lowjiansheng): The value is being floored, this might
        % introduce some inconsistencies to the solution.
        pos_lowest_eig(x, 1) = floor(pos_lowest_eig(x, 1) + d_window(1,1));
        pos_lowest_eig(x, 2) = floor(pos_lowest_eig(x, 2) + d_window(2,1));
    end
    pic_grey = pic_grey_next;
    debugger = debugger + 1
    
    % display frame together with the trackers
    imshow(pic_grey, [])
    for x = 1 : size(row_index)
        if isnan(pos_lowest_eig(x,1)) || isnan(pos_lowest_eig(x,2))
            continue
        end
        rectangle('Position', [pos_lowest_eig(x,2) - 6 , pos_lowest_eig(x,1) - 6, 13, 13], 'EdgeColor', 'r');
    end  
    print(figH, '-djpeg', num2str(debugger));
end
pos_lowest_eig;

