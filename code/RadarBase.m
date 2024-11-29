% Class defines a Radar base class. It provides default properties
% and common methods. It should not be called directly, but should
% instead be used as a superclass.
classdef RadarBase < keyValueInitializer

    % Public class properties
    properties
        carrierFreq     = 77e9;     % Carrier frequency (Hz)
        sampleRate      = 200e6;    % Sample rate (Hz)
        PRF             = 500e3;    % PRF (Hz)
        numPulses       = 16;       % Number of Pulses in CPI
        codeLength      = 127;      % Code length
        targetRange     = 50;       % Target range (m)
        targetVelocity  = 100;      % Target velocity (m/s)
        SNR_dB          = 20;       % Target SNR (dB)
        rangeOSR        = 1;        % Range Oversample Rate
        dopplerOSR      = 1;        % Doppler Oversample Rate
        normalizedUnits = false;    % Normalized units
        PSLRIgnoreGates = 3;        % How many gates to ignore on either
                                    % side of peak for PSLR measurement
    end

    % Protected class properties
    properties(Access=protected)
        priSamples;                 % PRI in samples
        rgSize;                     % Range gate size (m)
        lambda;                     % Wavelength (m)
        dopplerFreq;                % Doppler frequency (Hz)
        txWaveform;                 % Transmitted waveform
        rxData;                     % Received data
        rdm;                        % Range doppler matrix
        maxRangeGate;               % RDM peak range gate
        maxDopplerBin;              % RDM peak doppler bin
        targetPosEst;               % Estimated target position (m)
        targetVelEst;               % Estimated target velocity (m/s)
    end

    % Public class methods
    methods

        % Function runs radar model
        function run(self)
            self.getParameters();
            self.getTxWaveform();
            self.getRxData();
            self.generateRdm();
            self.locateTarget();
            self.computeMetrics();
            self.generatePlots();
        end
    end

    % Protected class methods
    methods (Access = protected)

        % Function computes dependent parameters from class properties
        function getParameters(self)
            self.priSamples = round(self.sampleRate/self.PRF);
            self.rgSize = physconst('LightSpeed')/(2*self.sampleRate);
            self.lambda = physconst('LightSpeed')/self.carrierFreq;
            self.dopplerFreq = 2*self.targetVelocity/self.lambda;
        end

        % Function generates transmitted waveform
        function getTxWaveform(~)
            % Override in subclass
        end

         % Function generates received waveform
        function getRxData(~)
            % Override in subclass
        end

        % Function generates RDMs from received data
        function generateRdm(~)
            % Override in subclass
        end

        % Function locates target in RDM and estimates
        % its range and velocity
        function locateTarget(self)

            % Find the range gate and doppler bin corresponding to
            % the RDM peak
            [maxVal,self.maxRangeGate] = max(abs(self.rdm));
            [~,self.maxDopplerBin] = max(abs(maxVal));
            self.maxRangeGate = self.maxRangeGate(self.maxDopplerBin);

            % Estimate target position
            self.targetPosEst = (self.maxRangeGate - 1) * ...
                self.rgSize / self.rangeOSR;

            % Estimate target velocity
            targetDopplerBin = self.maxDopplerBin - 1;
            numDopplerBins = size(self.rdm,2);
            if targetDopplerBin >= numDopplerBins/2
                targetDopplerBin = targetDopplerBin - numDopplerBins;
            end
            targetDopplerFreq = targetDopplerBin / ...
                numDopplerBins * self.PRF;
            self.targetVelEst = targetDopplerFreq * self.lambda / 2;

            % Print out estimates of target position
            fprintf('Estimated Target Position: %.2f m\n', self.targetPosEst);
            fprintf('Estimated Target Velocity: %.2f m/s\n\n', self.targetVelEst);
        end

        % Function computes Radar metrics
        function computeMetrics(self)

            % Grab range slice containing peak
            rangeSlice = self.rdm(:,self.maxDopplerBin);

            % Get peak value
            rdmPeak = abs(rangeSlice(self.maxRangeGate));

            % Grab peak sidelobe value
            % Ignore a subset of values around peak
            ignoreGates = self.PSLRIgnoreGates*self.rangeOSR;
            ignoreGates = ignoreGates + self.rangeOSR - 1;
            ignoreGates = self.maxRangeGate + (-ignoreGates:ignoreGates);
            ignoreGates = mod(ignoreGates - 1, size(self.rdm,1)) + 1;
            rangeGates = 1:size(self.rdm, 1);
            sidelobes = rangeSlice(all(rangeGates ~= ignoreGates.', 1));
            maxSidelobe = max(abs(sidelobes));

            % Compute peak sidelobe ratio
            PSLR_dB = 20*log10(rdmPeak/maxSidelobe);

            % Output peak sidelobe ratio
            fprintf('Radar Metrics:\n')
            fprintf('\tPSLR(dB) = %.2f\n\n', PSLR_dB)
        end

        % Function generates plot from computed RDMs
        function generatePlots(self)

            % FFT shift RDM
            rdmCentered = fftshift(self.rdm,2);

            % Doppler axis
            numDopplerBins = size(self.rdm,2);
            doppAxis = (0:(numDopplerBins-1)) - numDopplerBins/2;
            doppAxis = doppAxis/self.dopplerOSR;
            doppAxisLabel = 'Doppler Bin';

            % Doppler bins correspond to velocity
            if (~self.normalizedUnits)
                doppAxis = doppAxis/self.numPulses;
                doppAxis = doppAxis*self.PRF;
                doppAxis = doppAxis*self.lambda/2;
                doppAxisLabel = 'Velocity (m/s)';
            end

            % Range axis
            rangeAxis = 0:(size(self.rdm,1)-1);
            rangeAxis = rangeAxis/self.rangeOSR;
            rangeAxisLabel = 'Range Gate';

            % Range Gates correspond to range
            if (~self.normalizedUnits)
                rangeAxis = rangeAxis*self.rgSize;
                rangeAxisLabel = 'Range (m)';
            end

            % Plot RDM
            figure(1)
            clf;
            imagesc(doppAxis,rangeAxis,db(rdmCentered));
            colorbar;
            title('RDM')
            xlabel(doppAxisLabel);
            ylabel(rangeAxisLabel)

            % Plot range response
            figure(2)
            clf;
            plot(rangeAxis,db(self.rdm(:,self.maxDopplerBin)),'LineWidth',1.5);
            xlim([rangeAxis(1) rangeAxis(end)]);
            grid on;
            title('Range Response');
            xlabel(rangeAxisLabel);
            ylabel('Amplitude (dB)');

            % Plot doppler spectrum
            figure(3)
            clf;
            plot(doppAxis,db(rdmCentered(self.maxRangeGate,:)),'LineWidth',1.5);
            xlim([doppAxis(1) doppAxis(end)]);
            grid on;
            title('Doppler Slice');
            xlabel(doppAxisLabel);
            ylabel('Amplitude (dB)');
        end
    end
end