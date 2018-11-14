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
points = detectMinEigenFeatures(pic_grey, 'ROI', boundary);
min_pts = points.selectStrongest(50).Location;
for x = 1 : 50
    rectangle('Position', [min_pts(x,1) , min_pts(x,2), 13, 13], 'EdgeColor', 'r');
end

print(figH, '-djpeg', num2str(debugger));
pointTracker = vision.PointTracker('NumPyramidLevels', 6);
initialize(pointTracker, min_pts, pic_grey);

while hasFrame(mulReader)
    debugger = debugger + 1;
    figH = figure;
    vidFrameNext = readFrame(mulReader);
    pic_grey_next = double(rgb2gray(vidFrameNext - backgroundImage));
    [points, validity] = pointTracker(pic_grey_next);
    % points
    imshow(pic_grey_next, [])
    for x = 1 : 50
        rectangle('Position', [points(x,1), points(x,2), 13, 13], 'EdgeColor', 'r');
    end
    print(figH, '-djpeg', num2str(debugger));
end

