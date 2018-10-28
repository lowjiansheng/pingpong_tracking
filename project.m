mulReader = VideoReader('vid1.mp4');
lenVideo = mulReader.Duration;

% loop through the entire video to apply lucas kanade and harris corner detector.
curFrameNum = 1;
while hasFrame(mulReader)
    vidFrame = readFrame(mulReader);
    vidFrameNext = readFrame(mulReader);
    % first use Harris corner detector to detect for good features.
    % get the pixels
    pic_grey = double(rgb2gray(vidFrame));
    pic_grey_next = double(rgb2gray(vidFrame));
    currFrameNum = currFrameNum - 1;
  
    % PADDING FOR CURRENT FRAME: X coordinates offsets
    pic_x_offset = pic_grey(2:end, :);
    pic_x_offset_with_pad = [pic_x_offset; zeros(1, size(pic_grey,1))];
    Ix_matrix = pic_x_offset_with_pad - pic_grey;
    % Pad Ix_matrix's sides to 0.
    Ix_matrix(1,:) = zeros(1, size(pic_grey, 1));
    Ix_matrix(end,:) = zeros(1, size(pic_grey, 1));
    Ix_matrix(:,1) = zeros(size(pic_grey,2), 1);
    Ix_matrix(:,end) = zeros(size(pic_grey,2), 1);
    
    % PADDING FOR CURRENT FRAME: Y coordinates offsets
    pic_y_offset = pic_grey(:,2:end);
    pic_y_offset_with_pad = [pic_y_offset zeros(size(pic_grey,2), 1)];
    Iy_matrix = pic_y_offset_with_pad - pic_grey;
    % Pad Iy_matrix's sides to 0.
    Iy_matrix(1,:) = zeros(1, size(pic_grey, 1));
    Iy_matrix(end,:) = zeros(1, size(pic_grey, 1));
    Iy_matrix(:,1) = zeros(size(pic_grey,2), 1);
    Iy_matrix(:,end) = zeros(size(pic_grey,2), 1);
    
    % PADDING FOR CURRENT FRAME:
    current_frame_padded = pic_grey;
    current_frame_padded(1,:) = zeros(1, size(pic_grey, 1));
    current_frame_padded(end,:) = zeros(1, size(pic_grey, 1));
    current_frame_padded(:,1) = zeros(size(pic_grey,2), 1);
    current_frame_padded(:,end) = zeros(size(pic_grey,2), 1);
    % PADDING FOR NEXT FRAME:
    next_frame_padded = pic_grey;
    next_frame_padded(1,:) = zeros(1, size(pic_grey_next, 1));
    next_frame_padded(end,:) = zeros(1, size(pic_grey_next, 1));
    next_frame_padded(:,1) = zeros(size(pic_grey_next,2), 1);
    next_frame_padded(:,end) = zeros(size(pic_grey_next,2), 1);

    eig_min = zeros(floor(size(pic_grey, 1) / 7), floor(size(pic_grey, 2) / 7));
    % dx and dy stores all the dx and dy for all the points in the windows.
    dx = zeros(floor(size(pic_grey, 1) / 7), floor(size(pic_grey, 2) / 7));
    dy = zeros(floor(size(pic_grey, 1) / 7), floor(size(pic_grey, 2) / 7));
    for x = 1 : floor(size(pic_grey , 1) / 7)
        for y = 1 : floor(size(pic_grey, 2) / 7)
            % Take care when not multiple of 7. Ignore the last sample
            % point.
            if (x == floor(size(pic_grey,1)/7)) && (7*x + 6 > size(pic_grey, 1))
                continue
            end 
            if (y == floor(size(pic_grey,1)/7)) && (7*y + 6 > size(pic_grey, 1))
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
            
            % note(lowjiansheng): this array will be used for the Z matrix
            % in lucas kanade tracking algorithm
            Z = [S_ix_square S_ix_iy;
                            S_ix_iy S_iy_iy];            
            eig_values = eig(Z);
            eig_min(x, y) = min(eig_values);
            
            % constructing matrix b
            window_current_frame = current_frame_padded(initial_x : x * 7 + 6, initial_y : y * 7 + 6);
            window_next_frame = next_frame_padded(initial_x : x * 7 + 6, initial_y : y * 7 + 6);
            b = [sum((window_current_frame - window_next_frame) * neighbour_ix, 'all');
                sum((window_current_frame - window_next_frame) * neighbour_iy, 'all')];
            d_window = inverse(Z) * b;
            dx(x,y) = d_window(1,1);
            dy(x,y) = d_window(2,1);
        end
    end
    
    sorted_eigmin = sort(eig_min(:), 'descend');
    value_threshold = sorted_eigmin(200,1);
    % getting only the lowest 200 eigen value positions
    [row_index, col_index] = find(eig_min >= value_threshold);

    % accept d only for good features
    
end

