classdef radar < handle
    properties 
        carrierFreq    = 77e9;      % Carrier frequency (Hz)
        sampleRate     = 200e6;     % Sample rate (Hz)
        PRF            = 500e3;     % PRF (Hz)
        numPulses      = 16;        % Number of Pulses in CPI
        codeLength     = 127;       % Code length
        targetRange    = 50;        % Target range (m)
        targetVelocity = 0;         % Target velocity (m/s)
        SNR_dB         = 20;        % Target SNR (dB)
    end
    properties(Access=protected)
        maxRangeGate;
        maxDopplerBin;
        priSamples;
        rgSize;
        lambda;
        dopplerFreq;
        txWaveform;
        rxData;
        rdm;
        targetPosEst;
        targetVelEst;
    end
    methods
        function self = radar(varargin)
            for i = 1:2:nargin
                self.(varargin{i}) = varargin{i+1};
            end
        end
        function run(self)
            self.getParameters();
            self.getTxWaveform();
            self.getRxData();
            self.generateRdm();
            self.locateTarget();
        end
    end
    methods (Access = protected)
        function getParameters(self)
            self.priSamples = round(self.sampleRate/self.PRF);
            self.rgSize = physconst('LightSpeed')/(2*self.sampleRate);
            self.lambda = physconst('LightSpeed')/self.carrierFreq;
            self.dopplerFreq = 2*self.targetVelocity/self.lambda;
        end
        function locateTarget(self)

            % Find the range gate and doppler bin corresponding to
            % the RDM peak
            [maxVal,self.maxRangeGate] = max(abs(self.rdm));
            [~,self.maxDopplerBin] = max(abs(maxVal));
            self.maxRangeGate = self.maxRangeGate(self.maxDopplerBin);

            % Estimate target position
            self.targetPosEst = (self.maxRangeGate - 1) * self.rgSize;

            % Estimate target velocity
            targetDopplerFreq = (self.maxDopplerBin - 1) * self.PRF;
            self.targetVelEst = targetDopplerFreq * self.lambda / 2;

            % Print out estimates of target position
            fprintf('Estimated Target Position: %.2f m\n', self.targetPosEst);
            fprintf('Estimated Target Velocity: %.2f m/s\n', self.targetVelEst);
        end
        function getTxWaveform(~)
            % Override in subclass
        end
        function getRxData(self)

            % Compute target delay in gates
            targetDelay = 8*round(self.targetRange/self.rgSize) + 4;

            % Compute normalized doppler frequency
            dopplerFreqNorm = self.dopplerFreq/self.sampleRate;

            % Generate transmit data for entire CPI
            txData = repmat(self.txWaveform, self.numPulses, 1);

            txData = filter(ones(8,1),1,upsample(txData,8));
%             txData = upsample(txData,8);
            [b, a] = butter(5, 0.125);
            txData = filter(b,a,txData);

            % Get time axis
            n = (0:(length(txData)-1)).';

            % Generate Receive Data
            self.rxData = zeros(size(txData));

            % Receive data is superposition of all target returns
            for i = 1:length(targetDelay)
                self.rxData = self.rxData + 10^(self.SNR_dB(i)/20)*...
                    circshift(txData, targetDelay(i)).*...
                    exp(1i*2*pi*dopplerFreqNorm*n);
            end

%             self.rxData = self.rxData.*repmat(exp(1i*0.5*pi*n(1:self.priSamples)/self.priSamples), self.numPulses, 1);
            self.rxData = self.rxData(1:8:end);

            % Reshape into a data cube
            self.rxData = reshape(self.rxData, [], self.numPulses);

            % Add noise
            noise = complex(randn(size(self.rxData)),...
                randn(size(self.rxData)));
            self.rxData = self.rxData + noise;
        end
        function generateRdm(~)
            % Override in subclass
        end
    end
end