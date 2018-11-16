classdef Camera < handle
    %Camera Just another camera
    %   Detailed explanation goes here
    
    properties
        axes % Row-wise
        position
        calibration_mat
        f_len
        offsets
    end
    
    methods
        function obj = Camera(R,t)
            obj.axes = R;
            obj.position = t;
        end
        
        function outputArg = getHorizontalAxis(obj)
            outputArg = obj.axes(1,:);
        end
        
        function outputArg = getVerticalAxis(obj)
            outputArg = obj.axes(2,:);
        end
        
        function output = getOpticalAxis(obj)
            output = obj.axes(3,:);
        end
        
        function output = getOpticalAxisPlotCoordinates(obj)
            output = [obj.getOpticalAxis()+obj.position'
                    obj.position'];
        end
        
        function output = getHorizontalAxisPlotCoordinates(obj)
            output = [obj.getHorizontalAxis()+obj.position'
                    obj.position'];
        end
        
        function output = getVerticalAxisPlotCoordinates(obj)
            output = [obj.getVerticalAxis()+obj.position'
                    obj.position'];
        end
        
        function changeCoordinateSystem(obj, new_axes_in_old_axes, new_origin_from_old_origin)
            obj.axes = (inv(new_axes_in_old_axes)*obj.axes')';
            if exist('new_origin_from_old_origin', 'var')
                obj.position = obj.position + new_origin_from_old_origin;
            end
        end
        
        function setCalibrationMatrix(obj, calibration_mat)
            obj.calibration_mat = calibration_mat;
            obj.f_len = (obj.calibration_mat(1,1) + obj.calibration_mat(2,2))/2;
            obj.offsets = obj.calibration_mat(1:2,3);
        end
        
        function output = img_pt2dir_vec(obj, img_pts)
%             Assume img_pts are in the form of N x 2 matrix where the 2nd
%             dimension are x and y.
            offset_img_pts = img_pts - obj.offsets';
            dir_vecs = [offset_img_pts, zeros(size(img_pts,1), 1)+obj.f_len];
            output = (obj.axes'*dir_vecs')';
        end
    end
end

