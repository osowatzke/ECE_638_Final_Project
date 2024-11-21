classdef RadarBase < handle

    % Public class properties
    properties 
        carrierFreq     = 77e9;     % Carrier frequency (Hz)
        sampleRate      = 200e6;    % Sample rate (Hz)
        PRF             = 500e3;    % PRF (Hz)
        numPulses       = 16;       % Number of Pulses in CPI
        codeLength      = 127;      % Code length
        targetRange     = 50;       % Target range (m)
        targetVelocity  = 0;        % Target velocity (m/s)
        SNR_dB          = 20;       % Target SNR (dB)
        normalizedUnits = true;     % Normalized units
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

        % Class constructor. Takes key value pair of arguments to
        % initialize class properties. Ex: RadarBase('SNR_dB', 10)
        function self = RadarBase(varargin)
            for i = 1:2:nargin
                self.(varargin{i}) = varargin{i+1};
            end
        end

        % Function runs radar model
        function run(self)
            self.getParameters();
            self.getTxWaveform();
            self.getRxData();
            self.generateRdm();
            self.locateTarget();
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
        %  its range and velocity
        function locateTarget(self)

            % Find the range gate and doppler bin corresponding to
            % the RDM peak
            [maxVal,self.maxRangeGate] = max(abs(self.rdm));
            [~,self.maxDopplerBin] = max(abs(maxVal));
            self.maxRangeGate = self.maxRangeGate(self.maxDopplerBin);

            % Estimate target position
            self.targetPosEst = (self.maxRangeGate - 1) * self.rgSize;

            % Estimate target velocity
            targetDopplerFreq = (self.maxDopplerBin - 1)/...
                self.numPulses * self.PRF;
            self.targetVelEst = targetDopplerFreq * self.lambda / 2;

            % Print out estimates of target position
            fprintf('Estimated Target Position: %.2f m\n', self.targetPosEst);
            fprintf('Estimated Target Velocity: %.2f m/s\n', self.targetVelEst);
        end

        % Function generates plot from computed RDMs
        function generatePlots(self)

            % FFT shift RDM
            rdmCentered = fftshift(self.rdm,2);

            % Doppler axis
            doppAxis = (0:(self.numPulses-1)) - self.numPulses/2;
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
            title('Range Slice');
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