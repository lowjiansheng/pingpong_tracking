classdef Camera < handle
    %Camera Just another camera
    %   Detailed explanation goes here
    
    properties
        axes % Row-wise
        position
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
        
        function output = getPlotCoordinates(obj)
            output = [obj.getHorizontalAxis()+obj.position'
                    obj.position'
                    obj.getVerticalAxis()+obj.position'
                    obj.position'
                    obj.getOpticalAxis()+obj.position'
                    obj.position'];
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
    end
end

