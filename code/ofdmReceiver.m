% Class defines an OFDM reciever. It can be initialized as 
% ofdmReceiver('Name','Value') where 'Name' and 'Value' are
% property names and property values.
% 
% Ex: ofdmRx = ofdmReceiver('interpMethod','linear')
%
% Once class has been instantiated, it can be run as follows:
% 
% bits = ofdmRx.run(rxSignal)
%
classdef ofdmReceiver < keyValueInitializer
    
    % Public properties
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

    % Read only properties
    properties(SetAccess=protected)
        eqSymbols       = [];
    end

    % Public class methods
    methods

        % Function determines received bit stream from recevied signal
        function bits = run(self, rxSignal)

            % Determine received symbols with just fading (no noise)
            % Used in perfect (unattainable) channel estimate
            fadedSymbols = self.extractSymbols(self.fadedSignal);
            fadedSymbols = fadedSymbols(self.dataIndices, :);
            
            % Demodulate received signal
            rxSymbols = self.extractSymbols(rxSignal);

            % Extract pilots and data symbols
            dataSymbols = rxSymbols(self.dataIndices,:);
            rxPilots = rxSymbols(self.pilotIndices,:);

            % Create an OFDM equalizer object
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

            % Equalize received symbols
            self.eqSymbols = equalizer.run(dataSymbols, rxPilots);

            % Demodulate to form an array of bits
            bits = demodulateSymbols(self.eqSymbols,...
                self.modType, self.modOrder);

            bits = bits(:);
        end

        % Function extracts received symbols from receive signal
        function symbols = extractSymbols(self, signal)

            % Determine where to place FFT window
            % Should start after half cylic prefix and window
            symbolStart = self.cyclicPrefixLen/2 + self.windowLen + 1;
            symbolEnd = size(signal,1) - symbolStart + 1;

            % Take FFT over FFT window. FFT will demodulate
            % received signal to get received symbols
            symbols = signal(symbolStart:symbolEnd,:);
            symbols = fft(symbols);

        end
    end
end