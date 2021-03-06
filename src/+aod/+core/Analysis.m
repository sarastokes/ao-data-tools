classdef Analysis < aod.core.Entity
% Analysis
%
% Description:
%   Implements data analysis. Meant to be expanded by subclasses
%
% -------------------------------------------------------------------------
    properties
        analysisParameters
    end

    methods
        function obj = Analysis(parent)
            obj.allowableParentTypes = {'aod.core.Dataset', 'aod.core.Epoch', 'aod.core.Empty'};

            if nargin > 0
                obj.setParent(parent);
            end
        end
    
        function addParameter(obj, varargin)
            % ADDPARAMETER
            %
            % Syntax:
            %   obj.addParameter(paramName, value)
            %   obj.addParameter(paramName, value, paramName, value)
            %   obj.addParameter(struct)
            % -------------------------------------------------------------
            if nargin == 1
                return
            end
            if nargin == 2 && isstruct(varargin{1})
                S = varargin{1};
                k = fieldnames(S);
                for i = 1:numel(k)
                    obj.analysisParameters(k{i}) = S.(k{i});
                end
            else
                for i = 1:(nargin - 1)/2
                    obj.analysisParameters(varargin{(2*i)-1}) = varargin{2*i};
                end
            end
        end
    end

end 