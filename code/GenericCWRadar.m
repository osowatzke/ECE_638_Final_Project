classdef GenericCWRadar < RadarBase

    % Public class properties
    properties
        codeLen    = [];   % Code length
        analogOSR  = 8;    % Analog oversample rate
    end

    % Private class methods
    methods (Access=protected)

        % Function generates dependent parameters
        function getParameters(self)
            getParameters@RadarBase(self);
            if isempty(self.codeLen)
                self.codeLen = self.priSamples;
            else
                self.priSamples = self.codeLen;
                PRI = self.priSamples/self.sampleRate;
                self.PRF = 1/PRI;
            end
        end

        % Function generates transmitted waveform
        function getTxWaveform(self)
            
            % Create zadoff chu waveform
            self.txWaveform = zadoffChuGen(self.codeLen);
        end

        % Function generates received waveform
        function getRxData(self)

            % Compute analog rate
            analogRate = self.analogOSR*self.sampleRate;

            % Compute power of each target return
            targetPower_dB = self.SNR_dB - max(self.SNR_dB);

            % Compute noise power
            noisePower_dB = -max(self.SNR_dB);

            % Compute target delays at the analog rate
            targetDelay = round(self.analogOSR*self.targetRange/self.rgSize);

            % Compute normalized doppler frequency
            dopplerFreqNorm = self.dopplerFreq/analogRate;

            % Generate transmit data for entire CPI
            % Add extra pulse to account for matched filter response
            % accross CPI boundaries. (True for all CPIs but the first).
            txData = repmat(self.txWaveform, self.numPulses+1, 1);

            % ZOH transmitted data
            txData = repmat(txData(:).', self.analogOSR, 1);
            txData = txData(:);

            % Filter transmitted data with "analog" filter
            [b, a] = butter(5, 1/self.analogOSR);
            txData = filter(b,a,txData);

            % Get time axis
            n = (0:(length(txData)-1)).';

            % Generate Receive Data
            self.rxData = zeros(size(txData));

            % Receive data is superposition of all target returns
            for i = 1:length(targetDelay)
                self.rxData = self.rxData + 10^(targetPower_dB(i)/20)*...
                    circshift(txData, targetDelay(i)).*...
                    exp(1i*2*pi*dopplerFreqNorm*n);
            end

            % Downsample data
            self.rxData = self.rxData(1:8:end);

            % Add noise
            noise = 1/sqrt(2)*complex(randn(size(self.rxData)),...
                randn(size(self.rxData)));
            noise = 10^(noisePower_dB/20)*noise;
            self.rxData = self.rxData + noise;
        end

        % Function generates RDMs from received data
        function generateRdm(self)
            
            % Generate matched filter from transmitted waveform
            mf = flip(conj(self.txWaveform));

            % Filter received data with matched filter
            mfOut = filter(mf,1,self.rxData(:));

            % Remove first pulse (represents end of last CPI)
            % and trailing pulse (captured in next CPI)
            mfOut = mfOut((self.codeLen+1):end);

            % Reshape into data cube
            mfOut = reshape(mfOut,[],self.numPulses);

            % Perform doppler processing
            self.rdm = fft(mfOut, [], 2);
        end
    end
end