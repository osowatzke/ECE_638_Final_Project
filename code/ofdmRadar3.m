classdef ofdmRadar3 < RadarBase
    properties
        modType          = OFDM_DEFAULT.MOD_TYPE;
        modOrder         = OFDM_DEFAULT.MOD_ORDER;
        nSubcarriers     = OFDM_DEFAULT.NSUBCARRIERS;
        nDataCarriers    = OFDM_DEFAULT.NDATA_CARRIERS;
        nPilotCarriers   = OFDM_DEFAULT.NPILOT_CARRIERS;
        autoplacePilots  = OFDM_DEFAULT.AUTOPLACE_PILOTS;
        pilotCarriers    = OFDM_DEFAULT.PILOT_CARRIERS;
        nullDcSubcarrier = OFDM_DEFAULT.NULL_DC_SUBCARRIER;
        cyclicPrefixLen  = OFDM_DEFAULT.CYCLIC_PREFIX_LEN;
        windowLen        = OFDM_DEFAULT.WINDOW_LEN;
        fastTimeWin      = @(x)chebwin(x,80);
        slowTimeWin      = @(x)chebwin(x,80);
    end
    properties (SetAccess=protected)
        transmitter      = [];
        bits             = [];
        Fmf              = [];
    end
    methods
        function self = ofdmRadar3(varargin)
            self@RadarBase(varargin{:})
            keys = varargin(1:2:end);
            if ~any(strcmp(keys,'sampleRate'))
                self.sampleRate = OFDM_DEFAULT.SAMPLE_RATE;
            end
            if ~any(strcmp(keys,'carrierFreq'))
                self.carrierFreq = OFDM_DEFAULT.CARRIER_FREQ;
            end
        end
    end
    methods(Access=protected)
        % Function generates random bits
        function genRandomBits(self)

            % Determine the number of bits to generate
            bitsPerSymbol = log2(self.modOrder);
            numBits = self.numPulses * self.nDataCarriers * bitsPerSymbol;

            % Generate random bits
            self.bits = randi([0 1], numBits, 1);
        end
        function getParameters(self)
            self.priSamples = self.nSubcarriers + self.cyclicPrefixLen + ...
                2*self.windowLen;
            self.PRF = self.sampleRate/self.priSamples;
            getParameters@RadarBase(self);
        end
        function getTxWaveform(self)
            self.transmitter = ofdmTransmitter(...
                'modType',          self.modType,...       
                'modOrder',         self.modOrder,... 
                'nSubcarriers',     self.nSubcarriers,...
                'nDataCarriers',    self.nDataCarriers,...
                'nPilotCarriers',   self.nPilotCarriers,...
                'autoplacePilots',  self.autoplacePilots,...
                'pilotCarriers',    self.pilotCarriers,...   
                'nullDcSubcarrier', self.nullDcSubcarrier,...    
                'cyclicPrefixLen',  self.cyclicPrefixLen,...        
                'windowLen',        self.windowLen);

            self.genRandomBits();
            self.txWaveform = self.transmitter.run(self.bits);

            % Save FFT of matched filter
            self.Fmf = zeros(size(self.transmitter.symbols));
            self.Fmf(self.transmitter.dataIndices,:) = ...
                1./self.transmitter.dataSymbols;
            self.Fmf(self.transmitter.pilotIndices,:) = ...
                1./self.transmitter.pilotSymbols;

            % Account for padded symbols in Cyclic Prefix
            m = self.cyclicPrefixLen/2;
            k = (0:(size(self.Fmf,1)-1)).';
            self.Fmf = self.Fmf.*exp(-1i*2*pi*m*k/self.nSubcarriers);
        end
        function getRxData(self)
            
            targetRangeGate = round(self.targetRange/self.rgSize);

            doppFreqNorm = self.dopplerFreq/self.sampleRate;

            self.rxData = zeros(1, numel(self.txWaveform));
            n = (0:(length(self.rxData)-1));

            for i = 1:length(self.txWaveform)
                self.rxData = self.rxData + [zeros(1,targetRangeGate),...
                    self.txWaveform(1:(end-targetRangeGate))].*...
                    exp(1i*2*pi*doppFreqNorm*n);
            end

            self.rxData = reshape(self.rxData, size(self.txWaveform));
            self.rxData = awgn(self.rxData, self.SNR_dB, 'measured');
        end
        function generateRdm(self)
            startIdx = self.transmitter.cyclicPrefixLen +...
                self.transmitter.windowLen + 1;
            endIdx = startIdx + self.nSubcarriers - 1;
            Frx = fft(self.rxData(startIdx:endIdx,:));

            Fmfout = Frx.*self.Fmf;

            numActiveCarriers = self.nDataCarriers +...
                length(self.transmitter.pilotIndices);
            if self.nullDcSubcarrier
                numActiveCarriers = numActiveCarriers + 1;
            end
            window = self.fastTimeWin(numActiveCarriers);

            numZeros = self.nSubcarriers-numActiveCarriers;
            numZerosLow = ceil(numZeros/2);
            numZerosHigh = numZeros - numZerosLow;

            window = [zeros(numZerosLow,1); window; zeros(numZerosHigh,1)];
            window = ifftshift(window);

            mfOut = ifft(Fmfout.*window);

            window = self.slowTimeWin(self.numPulses).';
            self.rdm = fft(mfOut.*window,[],2);
        end
    end
end