classdef ofdmModel < handle

    % Public properties
    properties
        nSubcarriers = 64;          % Number of OFDM subcarriers
        nDataCarriers = 48;         % Number of OFDM data subcarriers
        nSymbols = 1e4;             % Number of OFDM symbols
        cyclicPrefixLen = 16;       % Length of cyclic prefix
        windowLen = 0;              % Length of window
        snrRange = 0:2:20;          % SNR range in dB
        modOrder = 4;               % Modulation Order
        modType = 'QAM';            % Modulation Type
        enRayleighFading = false;   % Enable rayleigh fading
        enPerfectChanEst = false;   % Enable perfect channel estimation
        interpMethod = 'linear';    % Interpolation method
        eqAlgorithm = 'mmse';       % Equalization algorithm
        sampleRate = 10e6;          % Sample Rate (Hz)
        maxDopplerShift = 100;      % Maximum Doppler Shift (Hz)
        boxcarFiltLen = 32;         % Equalization Boxcar filter length
        
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
        dataSymbols;
        txSignal;
        fadedSignal;
        snr;
        rxSymbols;
        rxPilots;
        ber;
    end

    % Public methods
    methods

        % Function runs OFDM simulation
        function run(self)
            self.getParameters();
            self.createTxSignal();
            self.runReceiver();
            self.plotResults();
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
            self.dataSymbols = self.modulate(self.bits);
            self.dataSymbols = reshape(self.dataSymbols, [], self.nSymbols);

            % Create empty array of symbols
            symbols = zeros(self.nSubcarriers, self.nSymbols);
            
            % Populate data subcarriers
            symbols(self.dataIndicesWrap,:) = self.dataSymbols;
            
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

        % Function runs OFDM receiver model
        function runReceiver(self)

            % Create rayleigh channel object
            rayleighChan = comm.RayleighChannel(...
                'PathDelays', 0,...
                'AveragePathGains', 0,...
                'SampleRate', self.sampleRate,...
                'MaximumDopplerShift', self.maxDopplerShift);

            % Initialize BER array
            self.ber = zeros(length(self.snrRange), 1);

            % Loop over all the received SNRs
            for i = 1:length(self.snrRange)

                % Select SNR from array
                self.snr = self.snrRange(i);

                % Apply fading
                if self.enRayleighFading
                    self.fadedSignal = rayleighChan(self.txSignal);
                else
                    self.fadedSignal = self.txSignal;
                end

                % Create received signal
                rxSignal = awgn(self.fadedSignal, self.snr, 'measured');

                % Extract symbols from received signal
                self.rxSymbols = self.extractSymbols(rxSignal);

                % Extract pilots from symbols
                self.rxPilots = self.rxSymbols(self.pilotIndicesWrap,:);
                
                % Extract data subcarriers
                self.rxSymbols = self.rxSymbols(self.dataIndicesWrap,:);

                % Perform equalization
                if self.enRayleighFading
                    self.equalize();
                end
                
                % Demodulate received symbols
                rxBits = self.demodulate(self.rxSymbols(:));

                % Calculate BER
                self.ber(i) = mean(rxBits ~= self.bits);
            end
        end

        % Function extracts symbols from received signal
        function symbols = extractSymbols(self, rxSignal)

            % Reshape signal
            rxSignal = reshape(rxSignal, [], self.nSymbols);

            % Determine start and end of data payload
            symbolStart = self.symbolPadLen+1;
            symbolEnd = symbolStart + self.nSubcarriers - 1;

            % remove window and cyclic prefix
            rxSignal = rxSignal(symbolStart:symbolEnd,:);

            % FFT to get estimate symbols
            symbols = fft(rxSignal, self.nSubcarriers, 1);
        end

        % Function equalizes received symbols
        function equalize(self)

            % Perfect channel estimate
            if self.enPerfectChanEst

                % Extract symbols from noise-free fading channel
                fadedSymbols = self.extractSymbols(self.fadedSignal);
                
                % Only include symbols on data subcarriers
                fadedSymbols = fadedSymbols(self.dataIndicesWrap,:);

                % Compute perfect channel response
                H = fadedSymbols./self.dataSymbols;

            % Non-ideal channel estimate
            else

                % Interpolate the response of the comb pilots
                H = zeros(size(self.dataSymbols));
                for i = 1:size(H,2)
                    H(:,i) = interp1(self.pilotIndicesWrap, self.rxPilots(:,i),...
                        self.dataIndicesWrap, self.interpMethod, 'extrap');
                end

                % Add moving average filter to lessen the effects of noise
                H = filter(ones(1,self.boxcarFiltLen)/self.boxcarFiltLen, 1, H, [], 2);
            end

            % Compute EQ weights
            if strcmpi(self.eqAlgorithm, 'mmse')
                eqWeights = conj(H)./(H.*conj(H) + 10^(-self.snr/10));
            elseif strcmpi(self.eqAlgorithm, 'zf')
                eqWeights = 1./H;
            else
                error('Unsupported EQ Algorithm. Please select from {''mmse'',''zf''}');
            end

            % Equalize received data
            self.rxSymbols = self.rxSymbols.*eqWeights;                
        end

        % Function plots results
        function plotResults(self)
            
            % Plot BER vs SNR
            figure(1);
            clf;
            semilogy(self.snrRange, self.ber, '-o', 'LineWidth', 1.5);

            % Compare with reference results when rading fading is enabled
            if self.enRayleighFading

                % Compute Eb_N0 for reference calculation. Will be lower
                % than SNR by a factor of 2 for complex constellations
                if ~strcmpi(self.modType,'psk') || self.modOrder ~= 2
                    Eb_N0 = self.snrRange - 10*log10(2);
                else
                    Eb_N0 = self.snrRange;
                end
            
                % Compute SNR offset for single carrier reference
                % Account for inactive subcarriers and windowing
                numActiveCarriers = self.nDataCarriers + length(self.pilotIndices);
                snrOffset = numActiveCarriers/self.nSubcarriers;
                snrOffset = snrOffset*mean(self.window.^2);
                snrOffset_dB = 10*log10(snrOffset);

                Eb_N0 = Eb_N0 - snrOffset_dB;

                % Plot reference BIT error rate
                hold on;
                ref = berfading(Eb_N0,self.modType,self.modOrder,1);
                semilogy(self.snrRange, ref, 'LineWidth', 1.5)
                legend('Measured', 'Reference')
            end

            % Label plot
            xlabel('SNR (dB)');
            ylabel('Bit Error Rate (BER)');
            title('OFDM BER vs. SNR');
            grid on;

            % Plot spectrum of transmitted signal
            figure(2)
            clf;
            pwelch(self.txSignal, [], [], [], 'centered')
            [pxx, f] = pwelch(self.txSignal, [], [], [], 'centered');
            plot(f/pi, db(pxx), 'LineWidth', 1.5);
            grid on;
            xlabel('Normalized  Frequency (\times \pi rad/sample)')
            ylabel('Power/frequency (dB/(rad/sample))')
            title('Power Spectral Density of Transmitted OFDM Signal');

            % Plot spectrum of transmitted signal
            figure(3)
            clf;
            scatter(real(self.rxSymbols(:)), imag(self.rxSymbols(:)));
            maxXLim = max(abs(xlim));
            maxYLim = max(abs(ylim));
            maxLim = max([maxXLim, maxYLim]);
            xlim([-maxLim maxLim]);
            ylim([-maxLim maxLim]);
            grid on;
            title('Received Constellation Diagram at High SNR');
            xlabel('In Phase');
            ylabel('Quadrature');
        end
    end
end