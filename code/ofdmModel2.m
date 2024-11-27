classdef ofdmModel2 < keyValueInitializer
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
        transmitter      = [];
        channel          = [];
        receiver         = [];
        bits             = [];
        txSignal         = [];
    end
    methods

        % Function generates random bits
        function genRandomBits(self)

            % Determine the number of bits to generate
            bitsPerSymbol = log2(self.modOrder);
            numBits = self.nSymbols * self.nDataCarriers * bitsPerSymbol;

            % Generate random bits
            self.bits = randi([0 1], numBits, 1);
        end

        function run(self)
            self.createTxSignal();
            self.runReceiver();
            self.plotResults();
        end

        function createTxSignal(self)

            self.genRandomBits();

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

            self.txSignal = self.transmitter.run(self.bits);

        end

        function runReceiver(self)

            self.ber = zeros(size(self.SNR_dB));

            for i = 1:length(self.SNR_dB)

                self.channel = ofdmChannel(...
                    'enRayleighFading', self.enRayleighFading,...
                    'maxDopplerShift',  self.maxDopplerShift,...
                    'sampleRate',       self.sampleRate,...
                    'SNR_dB',           self.SNR_dB(i));

                rxSignal = self.channel.run(self.txSignal);

                self.receiver = ofdmReceiver(...
                    'modType',          self.modType,...
                    'modOrder',         self.modOrder,...
                    'interpMethod',     self.interpMethod,...
                    'smoothingFilter',  self.smoothingFilter,...
                    'useIdealChanEst',  self.useIdealChanEst,...
                    'eqAlgorithm',      self.eqAlgorithm,...
                    'cyclicPrefixLen',  self.cyclicPrefixLen,...
                    'windowLen',        self.windowLen,...
                    'SNR_dB',           self.SNR_dB(i),...
                    'fadedSignal',      self.channel.fadedSignal,...
                    'txPilots',         self.transmitter.pilotSymbols,...
                    'txSymbols',        self.transmitter.dataSymbols,...
                    'pilotIndices',     self.transmitter.pilotIndices,...
                    'dataIndices',      self.transmitter.dataIndices);
    
                rxBits = self.receiver.run(rxSignal);

                self.ber(i) = mean(rxBits ~= self.bits);

            end
        end

        function refBer = computeRefBer(self)

            % Eb_N0 will be lower than SNR by a factor of two for
            %  complex constellations.
            if (strcmpi(self.modType,'psk') && self.modOrder == 2)
                Eb_N0 = self.SNR_dB;
            else
                Eb_N0 = self.SNR_dB - 10*log10(2);
            end
        
            % Determine the number of non-zero carriers
            nPilots = length(self.transmitter.pilotIndices);
            nonZeroCarriers = self.nDataCarriers + nPilots;
        
            % The SNR on each active subcarrier will be higher because the energy
            % is distributed over fewer subcarriers
            snrOffset = (self.nSubcarriers/nonZeroCarriers);
        
            % The SNR will also be higher when the window is '1'. Happens for all
            % samples input to the FFT
            snrOffset = snrOffset/mean(abs(self.transmitter.window).^2);
        
            % Convert SNR offset to dB
            snrOffset_dB = 10*log10(snrOffset);
        
            % Get effective Eb_N0 for each individual subcarrier
            Eb_N0 = Eb_N0 + snrOffset_dB;

            % Get reference results reference results
            if self.enRayleighFading
                refBer = berfading(Eb_N0,self.modType,self.modOrder,1);
            else
                refBer = berawgn(Eb_N0,self.modType,self.modOrder,1); 
            end
        end
        function plotResults(self)
            self.plotBer();
            self.plotTxSpectrum();
            self.plotRxConstellation();
        end
        function plotBer(self)
            figure(1)
            clf;
            semilogy(self.SNR_dB, self.ber, '-o', 'LineWidth', 1.5);

            % Plot reference and measured data on the same axis
            hold on;
            ref = self.computeRefBer();
            semilogy(self.SNR_dB, ref, 'LineWidth', 1.5)
            legend('Measured', 'Reference')

            % Label plot
            xlabel('SNR (dB)');
            ylabel('Bit Error Rate (BER)');
            title('OFDM BER vs. SNR');
            grid on;
        end
        function plotTxSpectrum(self)
            figure(2)
            clf;
            pwelch(self.txSignal(:), [], [], [], 'centered')
            [pxx, f] = pwelch(self.txSignal(:), [], [], [], 'centered');
            plot(f/pi, db(pxx), 'LineWidth', 1.5);
            grid on;
            xlabel('Normalized  Frequency (\times \pi rad/sample)')
            ylabel('Power/frequency (dB/(rad/sample))')
            title('Power Spectral Density of Transmitted OFDM Signal');
        end
        function plotRxConstellation(self)
            figure(3)
            clf;
            rxSymbols = self.receiver.eqSymbols;
            scatter(real(rxSymbols(:)), imag(rxSymbols(:)));
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
