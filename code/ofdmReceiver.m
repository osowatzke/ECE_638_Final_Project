classdef ofdmReceiver < keyValueInitializer
    properties
        modType         = OFDM_DEFAULT.MOD_TYPE;
        modOrder        = OFDM_DEFAULT.MOD_ORDER;
        interpMethod    = OFDM_DEFAULT.INTERP_METHOD;
        smoothingFilter = OFDM_DEFAULT.SMOOTHING_FILTER;
        useIdealChanEst = OFDM_DEFAULT.USE_IDEAL_CHAN_EST;
        eqAlgorithm     = OFDM_DEFAULT.EQ_ALGORITHM;
        cyclicPrefixLen = OFDM_DEFAULT.CYCLIC_PREFIX_LEN;
        windowLen       = OFDM_DEFAULT.WINDOW_LEN;
        SNR_dB          = OFDM_DEFAULT.SNR_DB(end);
        fadedSignal     = [];
        txPilots        = [];
        txSymbols       = [];
        pilotIndices    = [];
        dataIndices     = [];
    end
    properties
        eqSymbols       = [];
    end
    methods
        function self = ofdmReceiver(varargin)
            self@keyValueInitializer(varargin{:});
        end
        function bits = run(self, rxSignal)

            fadedSymbols = self.extractSymbols(self.fadedSignal);
            fadedSymbols = fadedSymbols(self.dataIndices, :);
            
            rxSymbols = self.extractSymbols(rxSignal);

            dataSymbols = rxSymbols(self.dataIndices,:);
            rxPilots    = rxSymbols(self.pilotIndices,:);

            equalizer   = ofdmEqualizer(...
                'interpMethod',     self.interpMethod,...
                'smoothingFilter',  self.smoothingFilter,...
                'useIdealChanEst',  self.useIdealChanEst,...
                'eqAlgorithm',      self.eqAlgorithm,...
                'SNR_dB',           self.SNR_dB,...
                'fadedSymbols',     fadedSymbols,...
                'txPilots',         self.txPilots,...
                'txSymbols',        self.txSymbols,...
                'pilotIndices',     self.pilotIndices,...
                'dataIndices',      self.dataIndices);

            self.eqSymbols = dataSymbols; %equalizer.run(dataSymbols, rxPilots);

            bits = demodulateSymbols(self.eqSymbols,...
                self.modType, self.modOrder);

            bits = bits(:);
        end
        function symbols = extractSymbols(self, signal)

            symbolStart = self.cyclicPrefixLen/2 + self.windowLen + 1;
            symbolEnd   = size(signal,1) - symbolStart + 1;

            symbols     = signal(symbolStart:symbolEnd,:);
            symbols     = fft(symbols);

        end
    end
end