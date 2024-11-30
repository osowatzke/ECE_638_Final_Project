% Class defines an OFDM transmitter. It can be initialized as 
% ofdmTransmitter('Name','Value') where 'Name' and 'Value' are
% property names and property values.
% 
% Ex: ofdmTx = ofdmTransmitter('modType','qam')
%
% Once class has been instantiated, it can be run as follows:
% 
% txSignal = ofdmTx.run(bits)
%
classdef ofdmTransmitter < keyValueInitializer

    % Public class properties
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

    % Read-only properties
    properties(SetAccess=protected)
        dataIndices;
        dataSymbols;
        pilotIndices;
        pilotSymbols;
        symbols;
        window;
    end

    % Public class methods
    methods
        
        function txSignal = run(self, bits)

            % Determine indices of pilot and data carriers
            [self.dataIndices, self.pilotIndices] = getSubcarriers(...
                'nSubcarriers',     self.nSubcarriers,...
                'nDataCarriers',    self.nDataCarriers,...
                'nPilotCarriers',   self.nPilotCarriers,...
                'autoplacePilots',  self.autoplacePilots,...
                'pilotCarriers',    self.pilotCarriers,...
                'nullDcSubcarrier', self.nullDcSubcarrier);

            % Modulate bits
            self.dataSymbols = modulateBits(bits,...
                self.modType, self.modOrder);

            % Reshape into an array of size
            % nDataCarriers x nSymbols
            self.dataSymbols = reshape(self.dataSymbols,...
                self.nDataCarriers, []);

            % Determine the number of pilots
            numPilots = length(self.pilotIndices);

            % Pilots are pseudo-random BPSK symbols
            s = RandStream('mt19937ar','Seed',0);
            self.pilotSymbols = randi(s, [0 1],...
                numPilots, size(self.dataSymbols, 2));
            self.pilotSymbols = cos(pi*self.pilotSymbols);

            % Allocate empty array of OFDM symbols
            self.symbols = zeros(self.nSubcarriers,...
                size(self.dataSymbols, 2));

            % Place data symbols on data carriers
            self.symbols(self.dataIndices, :) = self.dataSymbols;

            % Place pilot symbols on pilot carriers
            self.symbols(self.pilotIndices, :) = self.pilotSymbols;

            % Perform an IFFT to modulate carriers
            txSignal = ifft(self.symbols);

            % Add cyclic prefix. Cyclic prefix is extended by
            % 2*windowLen for ramp-up/down between symbols
            txSignalCP = addCylicPrefix(txSignal,...
                'cyclicPrefixLen', self.cyclicPrefixLen,...
                'windowLen', self.windowLen);

            % Apply raised cosine window to symbols
            self.window = raisedCosineWindow(self.nSubcarriers,...
                self.cyclicPrefixLen, self.windowLen);

            txSignal = txSignalCP.*self.window;

            % Overlapped windowed region of neighboring symbols
            symbolEnd = txSignal((end-self.windowLen+1):end,:);
            txSignal(1:self.windowLen,2:end) = ...
                txSignal(1:self.windowLen,2:end) + ...
                symbolEnd(:,1:(end-1));

            % Flatten into vector
            txSignal = reshape(txSignal(1:(end-self.windowLen),:),[],1);
            txSignal = [txSignal; symbolEnd(:,end)];
        end
    end
end