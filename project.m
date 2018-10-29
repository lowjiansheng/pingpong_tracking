% Overview of Lucas Kanade tracking + Harris corner detector
% 1. Use Harris corner detector to detect "good" features from the first
% frame.
% 2. Loop through the entire video, using LK tracker to track the good
% features.

% Reading the video file.
mulReader = VideoReader('vid1.mp4');
lenVideo = mulReader.Duration;
totalNumFrames = floor(lenVideo * mulReader.FrameRate)
% ball only appears after frame 10.
curFrameNum = 10;

% HARRIS CORNER DETECTOR. 
% Get top 200 corners.
vidFrame = readFrame(mulReader);
pic_grey = double(rgb2gray(vidFrame));

% PADDING FOR X coordinate offset: 
pic_x_offset = pic_grey(:, 2:end);
% size(pic_x_offset)
% size(zeros(size(pic_grey,1), 1))
pic_x_offset_with_pad = [pic_x_offset zeros(size(pic_grey,1), 1)];
Ix_matrix = pic_x_offset_with_pad - pic_grey;
% Pad Ix_matrix's sides to 0.
Ix_matrix(1,:) = zeros(1, size(pic_grey, 2));
Ix_matrix(end,:) = zeros(1, size(pic_grey, 2));
Ix_matrix(:,1) = zeros(size(pic_grey,1), 1);
Ix_matrix(:,end) = zeros(size(pic_grey,1), 1);
    
% PADDING FOR Y coordinate offset
pic_y_offset = pic_grey(2:end, :);
pic_y_offset_with_pad = [pic_y_offset; zeros(1, size(pic_grey,2))];
Iy_matrix = pic_y_offset_with_pad - pic_grey;
% Pad Iy_matrix's sides to 0.
Iy_matrix(1,:) = zeros(1, size(pic_grey, 2));
Iy_matrix(end,:) = zeros(1, size(pic_grey, 2));
Iy_matrix(:,1) = zeros(size(pic_grey,1), 1);
Iy_matrix(:,end) = zeros(size(pic_grey,1), 1);

eig_min = zeros(floor(size(pic_grey, 1) / 7), floor(size(pic_grey, 2) / 7));
for x = 1 : floor(size(pic_grey , 1) / 7)
    for y = 1 : floor(size(pic_grey, 2) / 7)
        % Take care when not multiple of 7. Ignore the last sample
        % point.
        if (x == floor(size(pic_grey,1)/7)) && (7*x + 6 > size(pic_grey, 1))
            continue
        end 
        if (y == floor(size(pic_grey,2)/7)) && (7*y + 6 > size(pic_grey, 2))
            continue
        end 
        
        initial_x = x * 7 - 6;
        initial_y = y * 7 - 6;
        neighbour_ix = Ix_matrix(initial_x : x * 7 + 6, initial_y : y * 7 + 6);
        neighbour_iy = Iy_matrix(initial_x : x * 7 + 6, initial_y : y * 7 + 6);   
        
        ix_square = (neighbour_ix .* neighbour_ix);
        S_ix_square = sum(ix_square, 'all');
        ix_iy = (neighbour_ix .* neighbour_iy);
        S_ix_iy = sum(ix_iy, 'all');
        iy_square = (neighbour_iy .* neighbour_iy);
        S_iy_iy = sum(iy_square, 'all');
        
        Z = [S_ix_square S_ix_iy;
             S_ix_iy S_iy_iy];            
        eig_values = eig(Z);
        eig_min(x, y) = min(eig_values);
        
    end
end

sorted_eigmin = sort(eig_min(:), 'descend');
value_threshold = sorted_eigmin(200,1);
% getting only the lowest 200 eigen value positions
[row_index, col_index] = find(eig_min >= value_threshold);
% pos_lowest_eig stores the position index of the corners of the image.
pos_lowest_eig = [row_index * 7, col_index * 7]
% END HARRIS CORNER DETECTOR.
debugger = 0;

while hasFrame(mulReader)
    % Error at last frame trying to fetch last frame's next frame.
    if curFrameNum == totalNumFrames
        break
    end  
    vidFrameNext = readFrame(mulReader);
    pic_grey_next = double(rgb2gray(vidFrameNext));
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
        % introduce some error to the solution.
        pos_lowest_eig(x, 1) = floor(pos_lowest_eig(x, 1) + d_window(1,1));
        pos_lowest_eig(x, 2) = floor(pos_lowest_eig(x, 2) + d_window(2,1));
    end
    pic_grey = pic_grey_next;
    debugger = debugger + 1

end
pos_lowest_eig

