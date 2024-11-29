% Class defines a FMCW radar. It can be initialized as 
% FMCWRadar('Name','Value') where 'Name' and 'Value' are
% property names and property values.
% 
% Ex: radar = FMCWRadar('sweepBandwidth',500e6)
%
% Once class has been instantiated, it can be run as follows:
% 
% radar.run()
%
classdef FMCWRadar < RadarBase

    % Public class properties
    properties
        sweepBandwidth = [];                % Sweep bandwidth (Hz)
        fastTimeWindow = @(L)rectwin(L);    % Fast time window function
        slowTimeWindow = @(L)rectwin(L);    % Slow time window function
    end

    % Protected class methods
    properties(Access=protected)
        sweepRate;  % Normalized sweep rate (rad/sample)
    end

    % Public class methods
    methods

        % Function extends the superclass constructor
        function self = FMCWRadar(varargin)

            % Call superclass constructor
            self = self@RadarBase(varargin{:});

            % Set bandwidth to sample rate if unspecified
            if isempty(self.sweepBandwidth)
                self.sweepBandwidth = self.sampleRate;
            end
        end
    end

    % Protected class methods
    methods(Access=protected)

        % Function generates parameters for the LFM waveform
        function getParameters(self)
            getParameters@RadarBase(self);
            self.sweepRate = self.sweepBandwidth/self.sampleRate/...
                self.priSamples;
        end

        % Function generates the transmitted waveform for an LFM radar
        function getTxWaveform(self)
            n = (0:(self.priSamples-1)).';
            self.txWaveform = exp(1i*pi*self.sweepRate*n.^2);
        end

        % Function generates received data for the Radar. It creates a
        % delayed version of transmitted signal analytically to avoid
        % discretizing target range. This is important for the FMCW
        % implementation because the code is generated in continuous time.
        function getRxData(self)

            % Compute power of each target return
            targetPower_dB = self.SNR_dB - max(self.SNR_dB);

            % Compute noise power
            noisePower_dB = -max(self.SNR_dB);

            % Compute target delay in gates
            targetDelay = self.targetRange/self.rgSize;

            % Compute normalized doppler frequency
            dopplerFreqNorm = self.dopplerFreq/self.sampleRate;

            % Generate Receive Data
            self.rxData = zeros(length(self.txWaveform)*self.numPulses, 1);

            % Get time axis for a CPI
            n = (0:(length(self.rxData)-1)).';

            % Receive data is superposition of all target returns
            for i = 1:length(targetDelay)
                txSigDelay = exp(1i*pi*self.sweepRate*...
                    (n(1:self.priSamples) - targetDelay(i)).^2);
                txSigDelay = repmat(txSigDelay, self.numPulses, 1);
                self.rxData = self.rxData + 10^(targetPower_dB(i)/20)*...
                    txSigDelay.*exp(1i*2*pi*dopplerFreqNorm(i)*n);
            end

            % Reshape into a data cube
            self.rxData = reshape(self.rxData, [], self.numPulses);

            % Add noise
            noise = 1/sqrt(2)*complex(randn(size(self.rxData)),...
                randn(size(self.rxData)));
            noise = noise*10^(noisePower_dB/20);
            self.rxData = self.rxData + noise;
        end

        % Function generates RDM from received waveform
        function generateRdm(self)

            % Mix signal with transmitted waveform
            % Will result in tone which can be sampled by ADC
            adcData = self.rxData.*conj(self.txWaveform);

            % Generate fast time window
            win = self.fastTimeWindow(length(adcData));

            % Fast time FFT
            self.rdm = fft(adcData.*win);

            % After mixing the target will be at a negative frequency
            % Flip the range axis so data is organized in "natural" order
            self.rdm = flip(self.rdm,1);

            % Generate slow time window
            win = self.slowTimeWindow(size(self.rdm, 2)).';
            
            % Slow time FFT
            self.rdm = fft(self.rdm.*win, [], 2);
        end
    end
end