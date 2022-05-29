classdef PhysiologyCreator < aod.core.Creator

    properties (SetAccess = private)
        Dataset
    end

    methods
        function obj = PhysiologyCreator(homeDirectory)
            obj@aod.core.Creator(homeDirectory);
        end

        function createDataset(obj, expDate, source, varargin)
            obj.Dataset = patterson.datasets.Physiology(obj.homeDirectory, expDate);
            obj.Dataset.addSource(source);
            obj.Dataset.initParameters(varargin{:});
        end

        function addEpochs(obj, epochIDs)
            for i = 1:numel(epochIDs)
                %try
                    obj.makeEpoch(epochIDs(i));
                % catch
                %    warning('Unable to add epoch %u, skipping', epochIDs(i));
                %end
            end
        end

        function makeEpoch(obj, epochID)
            ep = patterson.core.Epoch(epochID, obj.Dataset);
            obj.extractEpochAttributes(ep);
            obj.populateVideoNames(ep)
        end
    end

    methods %(Access = protected)
        function fName = getAttributeFile(obj, epochID)
            fName = sprintf('%u_%s_ref_%s.txt',...
                obj.Dataset.Source.ID, obj.Dataset.experimentDate,...
                int2fixedwidthstr(epochID, 4));
            fName = [obj.Dataset.homeDirectory, filesep, 'Ref', filesep, fName];
        end

        function extractEpochAttributes(obj, ep)
            epochID = ep.ID;
            fName = obj.getAttributeFile(epochID);

            ep.addFile('TrialFile', readProperty(fName, 'Trial file name = '));
            txt = strsplit(ep.files('TrialFile'), filesep);
            ep.addParameter('StimulusName', txt{end});

            ep.addParameter('RefPMT',...
                readProperty(fName, 'Reflectance PMT gain  = '));
            ep.addParameter('VisPMT',...
                readProperty(fName, 'Fluorescence PMT gain  = '));
        end

        function populateVideoNames(obj, ep)
            epochID = ep.ID;
            % Ref channel search parameters
            refFiles = ls([obj.Dataset.homeDirectory, 'Ref']);
            refFiles = string(deblank(refFiles));
            refStr = ['ref_', int2fixedwidthstr(epochID, 4)];
            % Vis channel search parameters
            visFiles = ls([obj.Dataset.homeDirectory, 'Vis']);
            visFiles = string(deblank(visFiles));
            visStr = ['vis_', int2fixedwidthstr(epochID, 4)];

            ep.addFile('RefVideo', ['Ref', filesep,...
                obj.Dataset.getEpochHeader(), '_', refStr, '.avi']);
            ep.addFile('VisVideo', ['Vis', filesep,...
                obj.Dataset.getEpochHeader(), '_', visStr, '.avi']);

            % Processed video for analysis
            ep.addFile('AnalysisVideo', ['Analysis', filesep, visStr, '.tif']);

            % Find registration report
            regFiles = refFiles(multicontains(refFiles, {'motion', 'csv'}));
            ind = find(contains(regFiles, refStr));
            if ~isempty(ind)
                % Return warning if > 1 registration files found
                if numel(ind) > 1
                    warning('%u registrations found for epoch %u, using first\n', ...
                        numel(ind), epochID);
                end
                ind = obj.checkFilesFound(ind);
                ep.addFile('RegistrationReport', refFiles(ind));
                % aod.builtin.readers.RegistrationReportReader(refFiles(ind));
            else
                warning('Registration report for epoch %u not found', epochID);
            end

            % Find registration parameters
            regFiles = refFiles(multicontains(refFiles, {'params', 'txt'}));
            ind = find(contains(regFiles, [refStr, '_']));
            if ~isempty(ind)
                ind = obj.checkFilesFound(ind);
                ep.addFile('RegistrationParameters', refFiles(ind));
            else
                warning('Registration parameters for epoch %u not found', epochID);
            end

            % Find stimulus reference images
            ind = find(contains(refFiles, [refStr, '_linear']));
            if ~isempty(ind)
                ind = obj.checkFilesFound(ind);
                ep.addFile('ReferenceImage', refFiles(ind));
            else
                warning('Registration parameters for epoch %u not found', epochID);
            end

            % Find frame registered videos 
            ind = find(multicontains(refFiles, {refStr, 'frame', '.avi'}));
            if ~isempty(ind)
                ind = obj.checkFilesFound(ind);
                ep.addFile('RefVideoFrameReg', refFiles(ind));
            else
                warning('Frame registered ref video for epoch %u not found', epochID);
            end

            ind = find(multicontains(visFiles, {visStr, 'frame', '.avi'}));
            if ~isempty(ind)
                ind = obj.checkFilesFound(ind);
                ep.addFile('VisVideoFrameReg', visFiles(ind));
            else
                warning('Strip registered ref video for epoch %u not found', epochID);
            end

            % Find strip registered videos
            ind = find(multicontains(refFiles, {refStr, 'strip', '.avi'}));
            if ~isempty(ind)
                ind = obj.checkFilesFound(ind);
                ep.addFile('RefVideoStripReg', refFiles(ind));
            else
                warning('Strip registered ref video for epoch %u not found', epochID);
            end

            ind = find(multicontains(visFiles, {visStr, 'strip', '.avi'}));
            if ~isempty(ind)
                ind = obj.checkFilesFound(ind);
                ep.addFile('VisVideoStripReg', visFiles(ind));
            else
                warning('Strip registered ref video for epoch %u not found', epochID);
            end
        end
    end

    methods (Static)
        function ind = checkFilesFound(ind)
            % CHECKFILESFOUND
            %
            % Syntax:
            %   ind = obj.checkFilesFound(ind)
            % -------------------------------------------------------------
            if numel(ind) > 1
                ind = ind(1);
            end
        end
    end
end