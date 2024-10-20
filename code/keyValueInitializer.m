% Key-value initializer base class
% Allows user to redefine the public properties of a class
% when instantiating it. (i.e. SampleClass('property1',value1))
classdef keyValueInitializer < handle
    methods
        function y = keyValueInitializer(varargin)
            for i = 1:2:nargin
                y.(varargin{i}) = varargin{i+1};
            end
        end
    end
end