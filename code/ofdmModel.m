% Class defines an OFDM model. It can be initialized as 
% ofdmModel('Name','Value') where 'Name' and 'Value' are
% property names and property values.
% 
% Ex: model = ofdmModel('modType','qam')
%
% Once class has been instantiated, it can be run as follows:
% 
% model.run()
%
classdef ofdmModel < keyValueInitializer

    % Public properties
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

    % Read-only properties
    properties(SetAccess=protected)
        ber              = [];
        transmitter      = [];
        channel          = [];
        receiver         = [];
        bits             = [];
        txSignal         = [];
        PAPR_dB          = [];
    end

    % Public class methods
    methods

        % Function runs the OFDM model
        function run(self)
            self.createTxSignal();
            self.runReceiver();
            self.getMetrics();
            self.plotResults();
        end

    end

    % Protected class methods
    methods(Access=protected)

        % Function generates random bits
        function genRandomBits(self)

            % Determine the number of bits to generate
            bitsPerSymbol = log2(self.modOrder);
            numBits = self.nSymbols * self.nDataCarriers * bitsPerSymbol;

            % Generate random bits
            self.bits = randi([0 1], numBits, 1);
        end

        % Functions creates the transmitted signal
        function createTxSignal(self)

            % Generate random bits
            self.genRandomBits();

            % Create an OFDM transmitter object
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

            % Create transmitted signal from bit stream
            self.txSignal = self.transmitter.run(self.bits);
        end

        % Function runs the OFDM receiver and channel models
        function runReceiver(self)

            % Create an empty array of bit error rates
            self.ber = zeros(size(self.SNR_dB));

            % Run the simulation for each SNR
            for i = 1:length(self.SNR_dB)

                % Create an OFDM channel object
                self.channel = ofdmChannel(...
                    'enRayleighFading', self.enRayleighFading,...
                    'maxDopplerShift',  self.maxDopplerShift,...
                    'sampleRate',       self.sampleRate,...
                    'SNR_dB',           self.SNR_dB(i));

                % Determine the received signal
                rxSignal = self.channel.run(self.txSignal);

                % Create an OFDM receiver object
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
    
                % Determine the received bits
                rxBits = self.receiver.run(rxSignal);

                % Compute the bit error rate for that run
                self.ber(i) = mean(rxBits ~= self.bits);
            end
        end

        % Function computes the OFDM metrics
        function getMetrics(self)

            % Compute peak to average power ratio
            avgPwr = mean(abs(self.txSignal).^2);
            peakPwr = max(abs(self.txSignal).^2);
            self.PAPR_dB = 10*log10(peakPwr/avgPwr);

            % Display Peak to average power ratio
            fprintf('OFDM Metrics:\n')
            fprintf('\tPSLR(dB) = %.2f\n\n', self.PAPR_dB)
        end

        % Function computes a reference bit error rate
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

            % Determine the power of the window
            windowPower = sum(abs(self.transmitter.window).^2);

            % Determine the number of samples in the window
            nSamplesWindow = length(self.transmitter.window);

            % Determine the average number of samples in the window
            % after accounting for overlap
            nSamplesWindowOverlap = nSamplesWindow - self.windowLen;
            avgSamplesWindow = (nSamplesWindowOverlap*(self.nSymbols - 1) + ...
                nSamplesWindow)/self.nSymbols;

            % Determine the average window power
            avgWindowPower = windowPower/avgSamplesWindow;

            % The SNR will also be higher when the window is 1.
            % Increase the SNR to account for non-unit samples
            snrOffset = snrOffset/avgWindowPower;
        
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

        % Function plots results
        function plotResults(self)
            self.plotBer();
            self.plotTxSpectrum();
            self.plotRxConstellation();
            self.plotTxSignal();
        end

        % Function plots the bit error rate
        function plotBer(self)

            % Determine the bit error rate
            ref = self.computeRefBer();

            % Create a new figure
            figure(1)
            clf;

            % Plot reference and measured data on the same axis
            semilogy(self.SNR_dB, self.ber, '-o', 'LineWidth', 1.5);
            hold on;
            semilogy(self.SNR_dB, ref, 'LineWidth', 1.5)

            % Label the plot
            xlabel('SNR (dB)');
            ylabel('Bit Error Rate (BER)');
            title('OFDM BER vs. SNR');
            legend('Measured', 'Reference')
            grid on;
        end

        % Function plots the spectrum of the transmitted signal
        function plotTxSpectrum(self)

            % Create a new figure
            figure(2)
            clf;

            % Determine the spectrum of the transmitted signal
            pwelch(self.txSignal, [], [], [], 'centered')
            [pxx, f] = pwelch(self.txSignal, [], [], [], 'centered');
            plot(f/pi, db(pxx), 'LineWidth', 1.5);
            grid on;

            % Label the plot
            xlabel('Normalized  Frequency (\times \pi rad/sample)')
            ylabel('Power/frequency (dB/(rad/sample))')
            title('Power Spectral Density of Transmitted OFDM Signal');
        end

        % Function plots the received constellation
        function plotRxConstellation(self)

            % Create a new figure
            figure(3)
            clf;

            % Plot the real and imaginary parts of the signals
            rxSymbols = self.receiver.eqSymbols;
            scatter(real(rxSymbols(:)), imag(rxSymbols(:)));
            grid on;

            % Scale the plot axis
            maxXLim = max(abs(xlim));
            maxYLim = max(abs(ylim));
            maxLim = max([maxXLim, maxYLim]);
            xlim([-maxLim maxLim]);
            ylim([-maxLim maxLim]);

            % Label the plot
            title('Received Constellation Diagram at High SNR');
            xlabel('In Phase');
            ylabel('Quadrature');
        end

        % Function plots the transmitted waveform
        function plotTxSignal(self)
    
            % Normalize transmitted signal
            signalPower = abs(self.txSignal)./max(abs(self.txSignal));

            % Create time axis
            timeAxis = 0:(length(signalPower)-1);
            timeAxis = timeAxis/self.sampleRate;

            % Plot peak to average power ratio
            figure(4)
            clf;
            plot(timeAxis, 20*log10(signalPower), 'LineWidth', 1.5);
            hold on;
            plot([timeAxis(1) timeAxis(end)], -self.PAPR_dB*ones(1,2), 'LineWidth', 1.5);
            xlim([timeAxis(1) timeAxis(end)])
            ylim([-20 0]);
            grid on;

            % Label Plot
            title('Plot of Signal')
            legend('Signal Power', 'Average Power');
            xlabel('time (s)')
            ylabel('Power (dB)')
        end
    end
end
