classdef Camera < handle
    %Camera Just another camera
    %   Detailed explanation goes here
    
    properties
        axes % Row-wise
        position
        calibration_mat
        f_len
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
        end
        
        function o = getFLen(obj)
            o = obj.f_len;
        end
    end
end

