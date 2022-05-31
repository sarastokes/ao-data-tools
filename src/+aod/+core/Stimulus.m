classdef Stimulus < aod.core.Entity
% STIMULUS
% 
% Constructor:
%   obj = aod.core.Stimulus(parent)
% -------------------------------------------------------------------------

    properties (SetAccess = protected)
        presentation                        timetable
        stimParameters                      % containers.Map 
    end
    
    methods
        function obj = Stimulus(parent)
            obj.allowableParentTypes = {'aod.core.Epoch'};
            if nargin == 1
                obj.setParent(parent);
            end
            obj.stimParameters = containers.Map();
        end
    end
end
