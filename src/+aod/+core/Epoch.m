classdef (Abstract) Epoch < aod.core.Entity 
% EPOCH
%
% Abstract methods:
%   videoName = getCoreVideoName(obj)
% 
% Public methods:
%   getStack(obj, varargin)
%   fName = getFilePath(obj, whichFile)
%   clearResponses(obj)
%   clearVideoCache(obj)
%
% Protected methods:
%   imStack = readStack(obj, videoName)
%
% aod.core.Creator methods:
%   addFile(obj, fileName, filePath)
%   addParameter(obj, paramName, paramValue)
%   addRegistration(obj, reg, overwrite)
%   addResponse(obj, resp)
%   addStimulus(obj, stim)
% -------------------------------------------------------------------------

    properties (SetAccess = private)
        ID(1,1)                     double     = 0
    end

    properties (SetAccess = {?aod.core.Creator, ?aod.core.Epoch})
        startTime(1,1)              datetime
        Registrations               % aod.core.Registration
        Responses                   % aod.core.Response  
        Stimuli                     % aod.core.Stimulus
        epochParameters             % aod.core.Parameters
        files                       % aod.core.Parameters  
    end

    properties (Dependent, Hidden)
        homeDirectory
    end

    properties (Hidden, Transient, Access = protected)
        cachedVideo
    end

    % Methods for subclasses to overwrite
    methods (Abstract, Access = protected)
        % Main analysis video name, accessed with 'getStack'
        videoName = getCoreVideoName(obj);
    end

    methods 
        function obj = Epoch(ID, parent)
            if nargin > 0
                obj.ID = ID;
            end

            obj.allowableParentTypes = {'aod.core.Dataset'};
            if nargin == 2
                obj.setParent(parent);
            end
            
            obj.epochParameters = aod.core.Parameters();
            obj.files = aod.core.Parameters();
        end

        function value = get.homeDirectory(obj)
            if ~isempty(obj.Parent)
                value = obj.Parent.homeDirectory;
            else
                value = [];
            end
        end
        
        function fName = getFilePath(obj, whichFile)
            % GETFILEPATH
            %
            % Syntax:
            %   fName = obj.getFilePath(whichFile)
            % -------------------------------------------------------------
            assert(isKey(obj.files, whichFile), sprintf('File named %s not found', whichFile));
            fName = obj.files(whichFile);
            if ~contains(fName, ':\')
                fName = obj.Parent.homeDirectory + fName;
            end
        end

        function clearVideoCache(obj)
            % CLEARVIDEOCACHE
            %
            % Syntax:
            %   obj.clearVideoCache()
            % -------------------------------------------------------------
            obj.cachedVideo = [];
        end
    end

    % Core methods
    methods 
        function imStack = getStack(obj)
            % GETSTACK
            %
            % Syntax:
            %   imStack = obj.getStack()
            % -------------------------------------------------------------
            if ~isempty(obj.cachedVideo)
                imStack = obj.cachedVideo;
                return;
            end

            videoName = obj.getCoreVideoName();
            imStack = obj.readStack(videoName);

            obj.cachedVideo = imStack;
        end

        function stim = getStimulus(obj, stimClassName)
            % GETSTIMULUS
            %
            % Syntax:
            %   stim = obj.getStimulus(stimClassName)
            %
            % Inputs:
            %   stimClassName       char, class of stimulus to retrieve
            % Ouputs:
            %   stim                aod.core.Stimulus or subclass
            % ----------------------------------------------------------
            stim = getByClass(obj.Stimuli, char(stimClassName));
        end
      
        function resp = getResponse(obj, responseClassName, varargin)
            % SETRESPONSE
            %
            % Syntax:
            %   resp = getResponse(obj, responseClassName, varargin)
            %   resp = getResponse(obj, responseClassName, Keep, varargin)
            %
            % Inputs:
            %   responseClassName    response name to compute
            % Optional inputs:
            %   keep                 Add to Epoch (default = false)
            % Additional key/value inputs are sent to response constructor
            % -------------------------------------------------------------

            ip = inputParser();
            ip.KeepUnmatched = true;
            addOptional(ip, 'Keep', false, @islogical);
            parse(ip, varargin{:});
            keepResponse = ip.Results.Keep;


            if isempty(obj.Parent.Regions)
                error('Dataset must contain Regions');
            end
            resp = getByClass(obj.Responses, responseClassName);
            if isempty(resp)
                constructor = str2func(responseClassName);
                resp = constructor(obj, ip.Unmatched);
                if keepResponse
                    obj.addResponse(resp);
                end
            end
        end

        function clearResponses(obj)
            % CLEARRESPONSES
            %
            % Syntax:
            %   obj.clearResponses()
            % -------------------------------------------------------------
            obj.Responses = [];
        end

        function clearRegionResponses(obj)
            % CLEARREGIONRESPONSES
            %
            % Syntax:
            %   obj.clearRegionResponses()
            % -------------------------------------------------------------
            if isempty(obj.Responses)
                return
            end
            idx = findByClass(obj.Responses, 'aod.core.responses.RegionResponse');
            if numel(obj.Responses) > 1
                obj.Responses{idx} = [];
            else
                obj.Responses(idx) = [];
            end
        end
    end

    methods (Access = protected)
        function imStack = readStack(~, videoName)
            % READSTACK
            %
            % Syntax:
            %   imStack = readStack(obj, videoName)
            % -------------------------------------------------------------
            [~, ~, extension] = fileparts(videoName);
            switch extension
                case {'.tif', '.tiff'}
                    reader = aod.core.readers.TiffReader(videoName);
                case '.avi'
                    reader = aod.core.readers.AviReader(videoName);
                otherwise
                    error('Unrecognized file extension!');
            end
            imStack = reader.read();
            fprintf('Loaded %s\n', videoName);
        end

        function value = getLabel(obj)  
            % GETLABEL
            % May be overwritten by subclasses          
            % -------------------------------------------------------------
            if isempty(obj.Parent)
                value = obj.shortName;
            else
                value = sprintf("Epoch%u_%s", obj.ID, obj.Parent.label);
            end
        end

        function shortName = getShortName(obj)
            % GETSHORTNAME
            % 
            % Syntax:
            %   shortName = obj.getShortName()
            % -------------------------------------------------------------
            shortName = sprintf('Epoch%u', obj.ID);
        end
    end

    methods (Access = {?aod.core.Creator, ?aod.core.Epoch})
        function addFile(obj, fileName, filePath)
            % ADDFILE
            %
            % Description:
            %   Adds to files prop, stripping out homeDirectory and
            %   trailing/leading whitespace, if needed
            %
            % Syntax:
            %   obj.addFile(fileName, filePath)
            % -------------------------------------------------------------
            filePath = erase(filePath, obj.Parent.homeDirectory);
            filePath = strtrim(filePath);
            obj.files(fileName) = filePath;
        end

        function addStimulus(obj, stim, overwrite)
            % ADDSTIMULUS
            %
            % Syntax:
            %   obj.addStimulus(stim, overwrite)
            % -------------------------------------------------------------
            if nargin < 3
                overwrite = false;
            end

            if ~isempty(obj.Stimuli)
                idx = find(findByClass(obj.Stimuli, stim));
                if ~isempty(idx) 
                    if ~overwrite
                        warning('Set overwrite=true to replace existing registration');
                        return
                    else
                        obj.Stimuli(idx) = stim;
                        return
                    end
                end
                obj.Stimuli = {obj.Stimuli; stim};
            else
                obj.Stimuli = stim;
            end
        end

        function addRegistration(obj, reg, overwrite)
            % ADDREGISTRATION
            %
            % Syntax:
            %   obj.addRegistration(reg, overwrite)
            % -------------------------------------------------------------
            if nargin < 3
                overwrite = false;
            end

            if ~isempty(obj.Registrations)
                idx = find(findByClass(obj.Registrations, class(reg)));
                if ~isempty(idx) 
                    if ~overwrite
                        warning('Set overwrite=true to replace existing registration');
                        return
                    else % overwrite existing
                        if numel(obj.Registrations) == 1
                            obj.Registrations = reg;
                        else
                            obj.Registrations{idx} = reg;
                        end
                        return
                    end
                end
                obj.Registrations = {obj.Registrations; reg};
            else
                obj.Registrations = reg;
            end
        end

        function addResponse(obj, resp, overwrite)
            % ADDRESPONSE
            %
            % Syntax:
            %   obj.addResponse(reg, overwrite)
            % -------------------------------------------------------------
            if nargin < 3
                overwrite = false;
            end

            if ~isempty(obj.Responses)
                idx = find(findByClass(obj.Responses, class(resp)));
                if ~isempty(idx)
                    if ~overwrite
                        warning('Set overwrite=true to replace existing %s', class(resp));
                        return
                    else  % Overwrite existing
                        if numel(obj.Responses) == 1
                            obj.Responses = resp;
                        else
                            obj.Responses{idx} = resp;
                        end
                        return
                    end
                end
                obj.Responses = {obj.Responses; resp};
            else
                obj.Responses = resp;
            end
        end
    end

    methods
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
                    obj.epochParameters(k{i}) = S.(k{i});
                end
            else
                for i = 1:(nargin - 1)/2
                    obj.epochParameters(varargin{(2*i)-1}) = varargin{2*i};
                end
            end
        end
    end
end 