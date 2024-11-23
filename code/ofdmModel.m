classdef ofdmModel < handle

    % Public properties
    properties
        nSubcarriers = 64;      % Number of OFDM subcarriers
        nDataCarriers = 1;      % Number of OFDM data subcarriers
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
        dataIndicesWrap;
        pilotIndicesWrap;
        zeroIndicesWrap;
        modulate;
        demodulate;
    end

    % Public methods
    methods

        % Function runs OFDM simulation
        function run(self)
            self.getParameters();
        end
    end

    % Protected methods
    methods (Access=protected)
        
        function getParameters(self)
            self.selectModulation();
            self.mapSubCarriers();
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
    end
end