% Overview of Lucas Kanade tracking + Harris corner detector
% 1. Use Harris corner detector to detect "good" features from the first
% frame.
% 2. Loop through the entire video, using LK tracker to track the good
% features.
% Note(lowjiansheng): Harris corner detector will return ALL corners in the
% frame instead of just at the ball. This might not be ideal.
% Lucas Kanade tracker loses track after a few frames. Will have to
% constantly redetect the points. 

% Reading the video file and getting some initial metadata.
mulReader = VideoReader('vid3_2.mp4');
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

mulReader.CurrentTime = 0.15;
vidFrame = readFrame(mulReader);
debugger = 1;
pic_grey = double(rgb2gray(vidFrame - backgroundImage));
figH = figure;
imshow(pic_grey,[]);
% Harris Corner Detector
corners = detectMinEigenFeatures(pic_grey);
corners = corners.selectStrongest(100).Location;
pointImage = insertMarker(vidFrame ,corners,'+','Color','red');
figH = figure;
imshow(pointImage);

% Initialise for LK tracker
pointTracker = vision.PointTracker('NumPyramidLevels', 6);
initialize(pointTracker, corners, pic_grey);

while hasFrame(mulReader)
    debugger = debugger + 1;
    vidFrameNext = readFrame(mulReader);
    pic_grey = double(rgb2gray(vidFrameNext - backgroundImage));
    % Every 4 (arbitrary) frames will redo Harris Corner
    if mod(debugger, 3) == 0
        points = detectMinEigenFeatures(pic_grey);
        points = points.selectStrongest(100).Location; 
        setPoints(pointTracker, points);
    else
        [points, validity] = pointTracker(pic_grey);
    end 
    % Visualising the points
    pointImage = insertMarker(vidFrameNext, points,'+','Color','red');
    imshow(pointImage);
end

