% Overview of Lucas Kanade tracking + Harris corner detector
% 1. Use Harris corner detector to detect "good" features from the first
% frame.
% 2. Loop through the entire video, using LK tracker to track the good
% features.

% Reading the video file and getting some initial metadata.
mulReader = VideoReader('vid1.mp4');
lenVideo = mulReader.Duration;
heightVideo = mulReader.Height;
widthVideo = mulReader.Width;
totalNumFrames = floor(lenVideo * mulReader.FrameRate);

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

% Doing thresholding of points to identify the ball in the first frame. 
mulReader.CurrentTime = 0.15;
vidFrame = readFrame(mulReader);
threshold_boundary = [1 1 1000 1000];
pic_grey = double(rgb2gray(vidFrame - backgroundImage));
debugger = 0;
figH = figure;
imshow(pic_grey, [])
threshold_intensity = 147;
pos = threshold_points(pic_grey, threshold_boundary, threshold_intensity);

% Use Harris Corner det to identify the corners near the ball to use for
% LK.
corners = harris_corner_det(pic_grey, pos, heightVideo, widthVideo);

for x = 1 : size(corners, 1)
    rectangle('Position', [corners(x,2) , corners(x,1), 5, 5], 'EdgeColor', 'r');
end
print(figH, '-djpeg', num2str(debugger));

% Initialising LK tracking to track the ball's next positions.
pointTracker = vision.PointTracker('NumPyramidLevels', 6);
initialize(pointTracker, corners, pic_grey);

while hasFrame(mulReader)
    debugger = debugger + 1;
    figH = figure;
    vidFrameNext = readFrame(mulReader);
    pic_grey_next = double(rgb2gray(vidFrameNext - backgroundImage));
    
    [points, validity] = pointTracker(pic_grey_next);
    points
    imshow(pic_grey_next, [])
    for x = 1 : size(pos, 1)
        rectangle('Position', [pos(x,2), pos(x,1), 13, 13], 'EdgeColor', 'r');
    end
    print(figH, '-djpeg', num2str(debugger));
end


function corners = harris_corner_det(pic_grey, pos, heightVideo, widthVideo)
    corners = [];
    for x = 1 : size(pos,1)
        % Will create a 30x30 boundary around the points identified.
        if pos(x,1) - 30 > 0
            boundary_x = pos(x,1) - 30;
        else 
            boundary_x = 1;
        end
        if pos(x,2) - 30 > 0
            boundary_y = pos(x,2) - 30;
        else
            boundary_y = 1;
        end
        if pos(x,1) + 30 > heightVideo
            size_x = heightVideo - boundary_x;
        else
            size_x = 60;
        end
        if pos(x,2) + 30 > widthVideo
            size_y = widthVideo - boundary_y;
        else
            size_y = 60;
        end
        harris_boundary = [boundary_x boundary_y size_x size_y];
        corner_res = detectMinEigenFeatures(pic_grey, 'ROI', harris_boundary);
        corners = [corners ; corner_res.selectStrongest(10).Location];
    end
end


% Boundary should be a 1x4 matrix. 
% [x_top_left, y_top_left, x_bottom_right, y_bottom_right]
function pos = threshold_points(pic_grey, boundary, threshold_intensity)
    pos = [];
    %boundary(1,1)
    %boundary(1,2)
    for i = boundary(1,1):boundary(1,3)
        for j = boundary(1,2):boundary(1,4)
            if pic_grey(i,j) >= threshold_intensity
                pos = [pos; i j];
            end
        end 
    end
end