classdef ofdmModulator < keyValueInitializer
    properties
        modType         = OFDM_DEFAULT.MOD_TYPE;
        modOrder        = OFDM_DEFAULT.MOD_ORDER;
        nSubcarriers    = OFDM_DEFAULT.NSUBCARRIERS;
        nDataCarriers   = OFDM_DEFAULT.NDATA_CARRIERS;
        pilotIndices    = OFDM_DEFAULT.PILOT_INDICES;
        useDcSubcarrier = OFDM_DEFAULT.USE_DC_SUBCARRIER;
        cyclicPrefixLen = OFDM_DEFAULT.CYCLIC_PREFIX_LEN;
        windowLen       = OFDM_DEFAULT.WINDOW_LEN;
    end
    properties(SetAccess=protected)
        dataIndices;
        dataSymbols;
        pilotSymbols;
        symbols;
        window;
    end
    methods
        function txSignal = run(self, bits)

            [self.dataIndices, self.pilotIndices] = getSubcarriers(...
                'nSubcarriers',    self.nSubcarriers,...
                'nDataCarriers',   self.nDataCarriers,...
                'pilotIndices',    self.pilotIndices,...
                'useDcSubcarrier', self.useDcSubcarrier);

            self.dataSymbols = modulateBits(bits,...
                self.modType, self.modOrder);

            self.dataSymbols = reshape(self.dataSymbols,...
                self.nDataCarriers, []);

            numPilots = length(self.pilotIndices);
            s = RandStream('mt19937ar','Seed',0);
            self.pilotSymbols = randi(s, [0 1],...
                numPilots, size(self.dataSymbols, 2));
            self.pilotSymbols = cos(pi*self.pilotSymbols);

            self.symbols = zeros(self.nSubcarriers,...
                size(self.dataSymbols, 2));

            self.symbols(self.dataIndices, :) = self.dataSymbols;

            self.symbols(self.pilotIndices, :) = self.pilotSymbols;

            txSignal = ifft(self.symbols);

            txSignalCP = addCylicPrefix(txSignal,...
                'cyclicPrefixLen', self.cyclicPrefixLen,...
                'windowLen', self.windowLen);

            self.window = raisedCosineWindow(self.nSubcarriers,...
                self.cyclicPrefixLen, self.windowLen);

            txSignal = txSignalCP.*self.window;
        end
    end
end