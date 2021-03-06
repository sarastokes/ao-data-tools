classdef TemporalModulation < aod.builtin.protocols.SpectralProtocol
% TEMPORALMODULATION
%
% Description:
%   A periodic temporal modulation
%
% Properties:
%   preTime
%   stimTime
%   tailTime
%   baseIntensity
%   contrast
%   temporalFrequency
%   sinewave           
% -------------------------------------------------------------------------
    properties
        temporalFrequency       % temporal frequency of modulation in Hz
        modulationClass         % 'sinewave' or 'squarewave'
    end

    properties (Dependent)
        temporalClass
    end

    methods
        function obj = TemporalModulation(ledMeans, varargin)
            obj = obj@aod.builtin.protocols.SpectralProtocol(ledMeans, varargin{:});

            ip = inputParser();
            ip.CaseSensitive = false;
            ip.KeepUnmatched = true;
            addParameter(ip, 'TemporalFrequency', 5, @isnumeric);
            addParameter(ip, 'ModulationClass', 'square', ...
                @(x) ismember(x, {'square', 'sine'}));
            parse(ip, varargin{:});

            obj.temporalFrequency = ip.Results.TemporalFrequency;
            obj.modulationClass = ip.Results.ModulationClass;
        end

        function value = get.temporalClass(obj)
            if obj.sinewave
                value = 'sine';
            else
                value = 'square';
            end
        end
    end

    methods
        function stim = generate(obj)
            dt = 1 / obj.stimRate;
            t = 0:dt:obj.stimTime-dt;
            stim = sin(2*pi*obj.temporalFrequency*t);
            if strcmp(obj.modulationClass, 'square')
                stim = sign(stim);
            end
            stim = stim * obj.baseIntensity + obj.baseIntensity;
            stim = obj.amplitude * stim;



            if obj.preTime > 0
                prePts = obj.sec2pts(obj.preTime);
                stim = [zeros(1, prePts), stim];
            end

            if obj.tailTime > 0
                tailPts = obj.sec2pts(obj.tailTime);
                stim = [stim, zeros(1, tailPts)];
            end
            stim = stim + obj.baseIntensity;
        end
        
        function fName = getFileName(obj)
            fName = sprintf('%s_%s_%s_%uhz_%up_%ut_%s.txt',...
                lower(char(obj.spectralClass)), obj.modulationClass,... 
                obj.temporalFrequency, 100*obj.baseIntensity, obj.totalTime);
                % datetime(datestr(now), 'Format', 'ddMMMuuuu'));
        end
    end
end
