classdef ofdmModel2 < keyValueInitializer
    properties
        modType          = OFDM_DEFAULT.MOD_TYPE;
        modOrder         = OFDM_DEFAULT.MOD_ORDER;
        nSubcarriers     = OFDM_DEFAULT.NSUBCARRIERS;
        nDataCarriers    = OFDM_DEFAULT.NDATA_CARRIERS;
        pilotCarriers    = OFDM_DEFAULT.PILOT_CARRIERS;
        nullDcSubcarrier = OFDM_DEFAULT.NULL_DC_SUBCARRIER;
        cyclicPrefixLen  = OFDM_DEFAULT.CYCLIC_PREFIX_LEN;
        windowLen        = OFDM_DEFAULT.WINDOW_LEN;
        enRayleighFading = OFDM_DEFAULT.EN_RAYLEIGH_FADING;
        maxDopplerShift  = OFDM_DEFAULT.MAX_DOPPLER_SHIFT;
        sampleRate       = OFDM_DEFAULT.SAMPLE_RATE;
        SNR_dB           = OFDM_DEFAULT.SNR_DB;
        nSymbols         = OFDM_DEFAULT.NSYMBOLS;
        interpMethod     = OFDM_DEFAULT.INTERP_METHOD;
        smoothingFilter  = OFDM_DEFAULT.SMOOTHING_FILTER;
        useIdealChanEst  = OFDM_DEFAULT.USE_IDEAL_CHAN_EST;
        eqAlgorithm      = OFDM_DEFAULT.EQ_ALGORITHM;
    end
    properties(SetAccess=protected)
        ber              = [];
    end
    methods

        % Function generates random bits
        function bits = genRandomBits(self)

            % Determine the number of bits to generate
            bitsPerSymbol = log2(self.modOrder);
            numBits = self.nSymbols * self.nDataCarriers * bitsPerSymbol;

            % Generate random bits
            bits = randi([0 1], numBits, 1);
        end

        function run(self)
            
            transmitter = ofdmTransmitter(...
                'modType',          self.modType,...
                'modOrder',         self.modOrder,...
                'nSubcarriers',     self.nSubcarriers,...
                'nDataCarriers',    self.nDataCarriers,...
                'pilotCarriers',    self.pilotCarriers,...
                'nullDcSubcarrier', self.nullDcSubcarrier,...
                'cyclicPrefixLen',  self.cyclicPrefixLen,...
                'windowLen',        self.windowLen);

            bits = self.genRandomBits();

            txSignal = transmitter.run(bits);

            self.ber = zeros(size(self.SNR_dB));

            for i = 1:length(self.SNR_dB)

                channel = ofdmChannel(...
                    'enRayleighFading', self.enRayleighFading,...
                    'maxDopplerShift',  self.maxDopplerShift,...
                    'sampleRate',       self.sampleRate,...
                    'SNR_dB',           self.SNR_dB(i));

                rxSignal = channel.run(txSignal);

                receiver = ofdmReceiver(...
                    'modType',          self.modType,...
                    'modOrder',         self.modOrder,...
                    'interpMethod',     self.interpMethod,...
                    'smoothingFilter',  self.smoothingFilter,...
                    'useIdealChanEst',  self.useIdealChanEst,...
                    'eqAlgorithm',      self.eqAlgorithm,...
                    'cyclicPrefixLen',  self.cyclicPrefixLen,...
                    'windowLen',        self.windowLen,...
                    'SNR_dB',           self.SNR_dB(i),...
                    'fadedSignal',      channel.fadedSignal,...
                    'txPilots',         transmitter.pilotSymbols,...
                    'txSymbols',        transmitter.dataSymbols,...
                    'pilotIndices',     transmitter.pilotIndices,...
                    'dataIndices',      transmitter.dataIndices);
    
                rxBits = receiver.run(rxSignal);

                self.ber(i) = mean(rxBits ~= bits);
            end
        end
    end
end
