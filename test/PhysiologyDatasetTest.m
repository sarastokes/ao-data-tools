classdef PhysiologyDatasetTest < matlab.unittest.TestCase

    properties 
        Dataset
        OldDataset
    end

    methods (TestClassSetup)
        function createDataset(testCase)
            S = load('MC00851_OSR_20220125A');
            obj.OldDataset = S.MC00851_OSR_20220125A;
            expDir = 'C:\Users\sarap\Dropbox\Postdoc\Data\AO\MC00851_20220125\';
            source = patterson.factories.SourceFactory(851, 'OS');
            x = patterson.creators.PhysiologyCreator(expDir);
            x.createDataset('20220125', source, 'Right',... 
                'Administrator', 'Sara Patterson',...
                'System', '1P primate',...
                'Purpose', 'RF mapping with vertical bars');

            x.addEpochs(6:39, patterson.EpochTypes.Spatial);
            regions = aod.builtin.regions.Rois(x.Dataset, '851_OSR_20220125_RoiSet.zip', [248, 360]);
            x.addRegions(regions);

            topticaEpochs = 6:39;
            x.addTransforms('851_OSR_20220125_rigid_ref29.txt',... 
                topticaEpochs(topticaEpochs ~= 29),...
                'TransformType', 'rigid', 'ReferenceEpoch', 29);
        end
    end

    methods (Test)
        function testStackImport(testCase)
            ep = testCase.Dataset.id2epoch(6);
            testCase.verifyEqual(...
                OldDataset.getEpochStack(6), ep.getStack(),...
                'Stacks were imported or transformed incorrectly');
        end   

        function testFluorescence(testCase)
            ep = testCase.Dataset.id2epoch(6);
            signals = testCase.OldDataset.getEpochResponses(6, []);
            TT = ep.getResponse('patterson.responses.Fluorescence');
            testCase.verifyEqual(...
                signals1(1, :), TT.Data.Signals(:,1),...
                'Flourescence does not match')
        end
    end
end 
