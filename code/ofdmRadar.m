% Class defines an OFDM radar. It can be initialized as 
% ofdmRadar('Name','Value') where 'Name' and 'Value' are
% property names and property values.
% 
% Ex: radar = FMCWRadar('modType','qam')
%
% Once class has been instantiated, it can be run as follows:
% 
% radar.run()
%
classdef ofdmRadar < RadarBase
    
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
        fastTimeWin      = @(x)chebwin(x,80);
        slowTimeWin      = @(x)chebwin(x,80);
    end

    % Read-only properties
    properties (SetAccess=protected)
        transmitter      = [];
        bits             = [];
        Fmf              = [];
    end

    % Public methods
    methods

        % Class constructor
        function self = ofdmRadar(varargin)

            % Call superclass constructor method
            self@RadarBase(varargin{:})

            % Get the name of properties overwritten in the constructor
            keys = varargin(1:2:end);

            % If sample rate was not overridden by user
            % Default to OFDM sample rate
            if ~any(strcmp(keys,'sampleRate'))
                self.sampleRate = OFDM_DEFAULT.SAMPLE_RATE;
            end

            % If carrier frequency was not overriden by user
            % Default to OFDM carrier frequency
            if ~any(strcmp(keys,'carrierFreq'))
                self.carrierFreq = OFDM_DEFAULT.CARRIER_FREQ;
            end
        end
    end

    % Protected class methods
    methods(Access=protected)

        % Function generates random bits
        function genRandomBits(self)

            % Determine the number of bits to generate
            bitsPerSymbol = log2(self.modOrder);
            numBits = self.numPulses * self.nDataCarriers * bitsPerSymbol;

            % Generate random bits
            self.bits = randi([0 1], numBits, 1);
        end

        % Function computes the clas parameters
        function getParameters(self)

            % Determine the PRI length in samples
            % Should be the same as OFDM symbol length
            self.priSamples = self.nSubcarriers + ...
                self.cyclicPrefixLen + self.windowLen;

            % Determine corresponding PRF length
            % Overrides PRF defined in radar base class
            self.PRF = self.sampleRate/self.priSamples;

            % Determine dependent parameters
            % Uses updated PRF result
            getParameters@RadarBase(self);
        end

        % Function computes the radar's transmitted waveform
        function getTxWaveform(self)

            % Create random stream of bits
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

            % Create the transmitted waveform
            self.txWaveform = self.transmitter.run(self.bits);

            % Determine FFT of matched filter
            % Should invert the spectrum of all nonzero symbols
            self.Fmf = zeros(size(self.transmitter.symbols));
            self.Fmf(self.transmitter.dataIndices,:) = ...
                1./self.transmitter.dataSymbols;
            self.Fmf(self.transmitter.pilotIndices,:) = ...
                1./self.transmitter.pilotSymbols;

            % Determine matched filter w.r.t. end of symbol. We sample
            % at the end of the symbol to ensure the signal we receive
            % is a circularly shifted copy of the transmission.

            % Employ DFT property to determine FFT of matched filter
            % at end of symbol. Delay by half of cyclic prefix length
            m = self.cyclicPrefixLen/2;
            k = (0:(size(self.Fmf,1)-1)).';
            self.Fmf = self.Fmf.*exp(-1i*2*pi*m*k/self.nSubcarriers);
        end

        % Function computes the radar's received data
        function getRxData(self)
            
            % Determine what gate the return will land in
            targetRangeGate = round(self.targetRange/self.rgSize);

            % Normalize the doppler frequency
            doppFreqNorm = self.dopplerFreq/self.sampleRate;

            % Allocate an empty array for the received data
            self.rxData = zeros(length(self.txWaveform),1);

            % Determine time axis for the CPI
            n = (0:(length(self.rxData)-1)).';

            % Received signal is superposition of all target returns
            % Each target return is a delay and doppler shifted
            % copy of the transmitted waveform
            for i = 1:length(targetRangeGate)
                self.rxData = self.rxData + [zeros(targetRangeGate(i),1);...
                    self.txWaveform(1:(end-targetRangeGate(i)))].*...
                    exp(1i*2*pi*doppFreqNorm(i)*n);
            end

            % Add complex gaussian noise to return
            self.rxData = awgn(self.rxData, self.SNR_dB, 'measured');

            % Remove half window length from leading and trailing
            % ends of received data. These overlap with last and next
            % CPI's respectively
            self.rxData = self.rxData((self.windowLen/2+1):(end-self.windowLen/2));

            % Reshape into a symbolLen x pulses matrix
            self.rxData = reshape(self.rxData, [], self.numPulses);
        end

        % Function generates an RDM from the received signal
        function generateRdm(self)

            % Determine where to sample the received signal. Sample at
            % the end of the symbol to ensure the signal we receive
            % is a circularly shifted copy of the transmission.
            startIdx = self.transmitter.cyclicPrefixLen +...
                self.transmitter.windowLen/2 + 1;
            endIdx = startIdx + self.nSubcarriers - 1;

            % Select relevant gates of the signal for FFT processing
            % and perform the FFT
            Frx = fft(self.rxData(startIdx:endIdx,:));

            % Perform a circular convolution with the matched filter
            % via a frequency domain multiplication
            Fmfout = Frx.*self.Fmf;

            % Determine the number of active carriers
            numActiveCarriers = self.nDataCarriers +...
                length(self.transmitter.pilotIndices);

            % Extend by 1 if the DC carrier is null
            if self.nullDcSubcarrier
                numActiveCarriers = numActiveCarriers + 1;
            end

            % Create a window for all the non-zero carriers
            window = self.fastTimeWin(numActiveCarriers);

            % Determine how many zeros have to be added to the window
            numZeros = self.nSubcarriers - numActiveCarriers;

            % Place an even number of zero at top and bottom of symbol
            numZerosLow = ceil(numZeros/2);
            numZerosHigh = numZeros - numZerosLow;

            % Concantenate window with zeros for all null carriers
            window = [zeros(numZerosLow,1); window; zeros(numZerosHigh,1)];

            % Inverse FFT shift window to match FFT ordering
            window = ifftshift(window);

            % Determine the size of the range IFFT
            rangeFftSize = size(Fmfout,1)*self.rangeOSR;

            % We can zero-pad the IFFT input, but we must perform zero
            % padding in the middle of the sequence
            mfIn = Fmfout.*window;
            padSize = (rangeFftSize - size(mfIn,1));
            zeroPad = zeros(padSize, size(mfIn, 2));
            mfIn = [mfIn(1:(size(mfIn,1)/2),:);...
                zeroPad; mfIn((end - size(mfIn,1)/2 + 1):end,:)];

            % Perform an inverse FFT
            mfOut = ifft(mfIn);

            % Create a slow-time window
            window = self.slowTimeWin(self.numPulses).';

            % Determine doppler FFT size
            dopplerFftSize = self.dopplerOSR*size(mfOut,2);

            % Muliply by the window and perform a slow-time FFT
            self.rdm = fft(mfOut.*window,dopplerFftSize,2);
        end
    end
end