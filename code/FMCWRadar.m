classdef FMCWRadar < RadarBase

    % Public class properties
    properties
        sweepBandwidth = [];            % Sweep bandwidth (Hz)
        fastTimeWin = @(L)rectwin(L);   % Fast time window function
        slowTimeWin = @(L)rectwin(L);   % Slow time window function
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
                    (n(1:self.priSamples) - targetDelay).^2);
                txSigDelay = repmat(txSigDelay, self.numPulses, 1);
                self.rxData = self.rxData + 10^(self.SNR_dB(i)/20)*...
                    txSigDelay.*exp(1i*2*pi*dopplerFreqNorm*n);
            end

            % Reshape into a data cube
            self.rxData = reshape(self.rxData, [], self.numPulses);

            % Add noise
            noise = complex(randn(size(self.rxData)),...
                randn(size(self.rxData)));
            self.rxData = self.rxData + noise;
        end

        % Function generates RDM from received waveform
        function generateRdm(self)

            % Mix signal with transmitted waveform
            % Will result in tone which can be sampled by ADC
            adcData = self.rxData.*conj(self.txWaveform);

            % Generate fast time window
            win = self.fastTimeWin(length(adcData));

            % Fast time FFT
            self.rdm = fft(adcData.*win);

            % After mixing the target will be at a negative frequency
            % Flip the range axis so data is organized in "natural" order
            self.rdm = flip(self.rdm,1);

            % Generate slow time window
            win = self.slowTimeWin(size(self.rdm, 2)).';
            
            % Slow time FFT
            self.rdm = fft(self.rdm.*win, [], 2);
        end
    end
end