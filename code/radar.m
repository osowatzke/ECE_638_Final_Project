classdef radar < handle
    properties 
        carrierFreq    = 77e9;      % Carrier frequency (Hz)
        sampleRate     = 200e6;     % Sample rate (Hz)
        PRF            = 500e3;     % PRF (Hz)
        numPulses      = 16;        % Number of Pulses in CPI
        pulsedDoppler  = false;     % Pulsed doppler mode
        waveformType   = 'LFM';     % Waveform type
        codeLength     = 127;       % Code length        
        isFMCW         = false;     % Is FMCW
        targetRange    = 50;        % Target range (m)
        targetVelocity = 0;         % Target velocity (m/s)
        SNR_dB         = 20;        % Target SNR (dB)
    end
    properties(Access=protected)
        priSamples;
        rgSize;
        lambda;
        dopplerFreq;
        txWaveform;
        rxData;
        rdm;
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
        end
    end
    methods (Access = protected)
        function getParameters(self)
            self.priSamples = round(self.sampleRate/self.PRF);
            self.rgSize = physconst('LightSpeed')/(2*self.sampleRate);
            self.lambda = physconst('LightSpeed')/self.carrierFreq;
            self.dopplerFreq = 2*self.targetVelocity/self.lambda;
        end
        function getTxWaveform(~)
            % Override in subclass
        end
        function getRxData(self)

            % Compute target delay in gates
            targetDelay = round(self.targetRange/self.rgSize);

            % Compute normalized doppler frequency
            dopplerFreqNorm = self.dopplerFreq/self.sampleRate;

            % Generate transmit data for entire CPI
            txData = repmat(self.txWaveform, self.numPulses, 1);

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