classdef ofdmTransmitter < keyValueInitializer
    properties
        modType          = OFDM_DEFAULT.MOD_TYPE;
        modOrder         = OFDM_DEFAULT.MOD_ORDER;
        nSubcarriers     = OFDM_DEFAULT.NSUBCARRIERS;
        nDataCarriers    = OFDM_DEFAULT.NDATA_CARRIERS;
        pilotCarriers    = OFDM_DEFAULT.PILOT_CARRIERS;
        nPilotCarriers   = OFDM_DEFAULT.NPILOT_CARRIERS;
        autoplacePilots  = OFDM_DEFAULT.AUTOPLACE_PILOTS;
        nullDcSubcarrier = OFDM_DEFAULT.NULL_DC_SUBCARRIER;
        cyclicPrefixLen  = OFDM_DEFAULT.CYCLIC_PREFIX_LEN;
        windowLen        = OFDM_DEFAULT.WINDOW_LEN;
    end
    properties(SetAccess=protected)
        dataIndices;
        dataSymbols;
        pilotIndices;
        pilotSymbols;
        symbols;
        window;
    end
    methods
        function txSignal = run(self, bits)

            [self.dataIndices, self.pilotIndices] = getSubcarriers(...
                'nSubcarriers',     self.nSubcarriers,...
                'nDataCarriers',    self.nDataCarriers,...
                'nPilotCarriers',   self.nPilotCarriers,...
                'autoplacePilots',  self.autoplacePilots,...
                'pilotCarriers',    self.pilotCarriers,...
                'nullDcSubcarrier', self.nullDcSubcarrier);

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