classdef ofdmModel < handle

    % Public properties
    properties
        nSubcarriers = 64;      % Number of OFDM subcarriers
        nDataCarriers = 48;     % Number of OFDM data subcarriers
        nSymbols = 1e4;         % Number of OFDM symbols
        cyclicPrefixLen = 16;   % Length of cyclic prefix
        windowLen = 4;          % Length of window
        snrRange = 0:2:20;      % SNR range in dB
        modOrder = 4;           % Modulation Order
        modType = 'QAM';        % Modulation Type

        % Pilot indices (defaulted to 802.11a pilots)
        pilotIndices = [-21, -7, 7, 21];
    end

    % Private properties
    properties(Access=protected)
        modulate;
        demodulate;
        dataIndicesWrap;
        pilotIndicesWrap;
        zeroIndicesWrap;
        symbolPadLen;
        window;
        bits;
        txSignal;
    end

    % Public methods
    methods

        % Function runs OFDM simulation
        function run(self)
            self.getParameters();
            self.createTxSignal();
        end
    end

    % Protected methods
    methods (Access=protected)
        
        function getParameters(self)
            self.selectModulation();
            self.mapSubCarriers();
            self.getPadLength(); 
            self.computeWindow();
        end

        % Function maps zero and data subcarriers to set of subcarriers
        function mapSubCarriers(self)

            % Get detailed carrier counts
            nPilots = length(self.pilotIndices);
            nZeroCarriers = self.nSubcarriers - self.nDataCarriers - nPilots;

            % Compute indices of zero carriers. 1 zero carrier at center of FFT.
            % Other zero carriers distributed at edges of FFT.
            if (self.nDataCarriers < self.nSubcarriers)
                nZeroCarriersLow = ceil((nZeroCarriers-1)/2);
                nZeroCarriersHigh = nZeroCarriers - nZeroCarriersLow - 1;
                zeroIndicesLow = -self.nSubcarriers/2 + (0:(nZeroCarriersLow-1));
                zeroIndicesHigh = self.nSubcarriers/2 - (nZeroCarriersHigh:-1:1);
                zeroIndices = [zeroIndicesLow, 0, zeroIndicesHigh];
            
            % Allow user to bypass zero subcarriers
            else
                self.zeroIndicesWrap = [];
            end

            % Convert indices to values in range [1, N] instead of [-N/2, N/2)
            self.pilotIndicesWrap = sort(self.pilotIndices + ...
                (self.pilotIndices < 0) * self.nSubcarriers) + 1;
            self.zeroIndicesWrap  = sort(zeroIndices + ...
                (zeroIndices < 0) * self.nSubcarriers) + 1;

            % Determine data subcarriers indices
            self.dataIndicesWrap = setdiff(1:self.nSubcarriers,...
                [self.pilotIndicesWrap, self.zeroIndicesWrap]);
        end

        % Function selects modulation and demodulation routines
        function selectModulation(self)
            if strcmpi(self.modType, 'psk')
                self.modulate = @(x) pskmod(x, self.modOrder,...
                    'InputType', 'bit');
                self.demodulate = @(x) pskdemod(x, self.modOrder,...
                    'OutputType', 'bit');
            elseif strcmpi(self.modType, 'qam')
                self.modulate = @(x) qammod(x, self.modOrder,...
                    'InputType', 'bit', 'UnitAveragePower', true);
                self.demodulate = @(x) qamdemod(x, self.modOrder,...
                    'OutputType', 'bit', 'UnitAveragePower', true);
            else
                error('Unsupported modulation type. Select from {''QAM'',''PSK''}');
            end
        end

        % Function computes the window
        function computeWindow(self)

            % Window is fixed at '1' during symbol and cyclic prefix
            self.window = hanning(2*self.windowLen + 1);
            self.window = [self.window(1:self.windowLen);
                ones(self.nSubcarriers+self.cyclicPrefixLen,1);
                self.window((end-self.windowLen+1):end)];
        end

        % Function computes symbol padding length
        % Padding is on either signal of transmitted symbols
        % And includes contributes from cyclic prefix and windowing
        function getPadLength(self)
            self.symbolPadLen = self.cyclicPrefixLen/2 + self.windowLen;
        end

        % Function generates random bits
        function genRandomBits(self)

            % Determine the number of bits to generate
            bitsPerSymbol = log2(self.modOrder);
            numBits = self.nSymbols * self.nDataCarriers * bitsPerSymbol;

            % Generate random bits
            self.bits = randi([0 1], numBits, 1);
        end

        % Function creates transmitted signal
        function createTxSignal(self)

            % Generate random bits
            self.genRandomBits();

            % Modulate bits
            dataSymbols = self.modulate(self.bits);
            dataSymbols = reshape(dataSymbols, [], self.nSymbols);

            % Create empty array of symbols
            symbols = zeros(self.nSubcarriers, self.nSymbols);
            
            % Populate data subcarriers
            symbols(self.dataIndicesWrap,:) = dataSymbols;
            
            % Insert pilots and zero carriers
            % Default pilots to 1 (should be pseudo-random)
            symbols(self.pilotIndicesWrap, :) = 1;
            symbols(self.zeroIndicesWrap, :) = 0;

            % OFDM modulation
            % IFFT per OFDM symbol
            self.txSignal = ifft(symbols, self.nSubcarriers, 1);

            % Add cyclic prefix
            self.addCylicPrefix();

            % Serialize transmitted signal
            self.txSignal = self.txSignal(:);
        end
        
        % Function adds cyclic prefix
        function addCylicPrefix(self)
            
            % Add cyclic prefix and transition region for window
            % Distribute evenly at start and end of symbol
            symbolPadStart = self.txSignal((end-self.symbolPadLen+1):end,:);
            symbolPadEnd = self.txSignal(1:self.symbolPadLen,:);
            self.txSignal = [symbolPadStart; self.txSignal; symbolPadEnd];
        end
    end
end