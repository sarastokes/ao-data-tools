classdef SpatialStimulus < aod.core.Stimulus 
%
% Inherited properties:
%   stimParameters
%
% Inherited methods:
%   addParameter(obj, paramName, paramValue)
% -------------------------------------------------------------------------

    properties (SetAccess = private)
        protocolName
    end

    properties (SetAccess = private)
        defaultProtocolFile     % Used for display name
    end

    methods
        function obj = SpatialStimulus(parent, protocol)
            if nargin < 1
                parent = [];
            end
            obj = obj@aod.core.Stimulus(parent);
            if nargin > 1
                obj.protocolName = class(protocol);
                obj.getProtocolParameters(protocol);
                obj.defaultProtocolFile = protocol.getFileName();
            end
        end

        function protocol = getProtocol(obj)
            % GETPROTOCOL
            %
            % Description:
            %   Use properties to regenerate the Protocol object
            %
            % Syntax:
            %   protocol = getProtocol(obj)
            % ----------------------------------------------------------
            protocolFcn = str2func(obj.protocolName);
            protocol = protocolFcn(map2struct(obj.stimulusParameters));
            if isempty(obj.Protocol)
                obj.Protocol = protocol;
            end
        end
    end

    methods (Access = private)
        function getProtocolParameters(obj, protocol)
            % GETPROTOCOLPARAMETERS
            %
            % Description:
            %   Move protocol properties to stimulusProperties
            % -------------------------------------------------------------
            mc = metaclass(protocol);
            for i = 1:numel(mc.PropertyList)
                if strcmp(mc.PropertyList(i).GetAccess, 'public')
                    obj.addParameter(mc.PropertyList(i).Name,...
                        protocol.(mc.PropertyList(i).Name));
                end
            end
        end
    end

    methods (Access = protected)
        function value = getDisplayName(obj)
            value = [];
            txt = strsplit(obj.defaultProtocolFile, '_');
            for i = 1:numel(txt)
                value = [value, capitalize(txt{i})]; %#ok<AGROW> 
            end
        end
    end
end