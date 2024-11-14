% MATLAB OFDM Simulation with Cyclic Prefix, Pilots, Zeroing, Windowing

% Parameters
nSubcarriers = 64;        % Number of OFDM subcarriers
nSymbols = 100;           % Number of OFDM symbols
cyclicPrefixLen = 16;     % Length of cyclic prefix
windowLen = 4;            % Length of window
snrRange = 0:2:20;        % SNR range in dB
pilotIndices = 1:8:nSubcarriers;  % Pilot every 8 subcarriers
zeroIndices = [1:5, (nSubcarriers-4):nSubcarriers];  % Zeroed subcarriers

% QPSK Modulation
modOrder = 4;
bitsPerSymbol = log2(modOrder);

% Get detailed carrier counts
nZeroCarriers = length(zeroIndices);
nPilots = length(setdiff(pilotIndices, zeroIndices));
nDataSubCarriers = nSubcarriers - nPilots - nZeroCarriers;
if nPilots ~= length(pilotIndices)
    warning(['Pilots overlap with zero carriers. ', ...
        'All overlapping carriers will default to zero subcarriers.']);
end

% Determine data subcarriers indices
dataIndices = setdiff(1:nSubcarriers,[pilotIndices, zeroIndices]); 

% Generate random bits
bits = randi([0 1], nSymbols * nDataSubCarriers * bitsPerSymbol, 1);

% Reshape bits into QPSK symbols
dataSymbols = qammod(bits, modOrder, 'InputType', 'bit', 'UnitAveragePower', true);
dataSymbols = reshape(dataSymbols, [], nSymbols);

% Create empty array of symbols
symbols = zeros(nSubcarriers, nSymbols);

% Populate data subcarriers
symbols(dataIndices,:) = dataSymbols;

% Insert pilots and zeroing
symbols(pilotIndices, :) = 1;         % Pilots set to 1
symbols(zeroIndices, :) = 0;          % Zeroed subcarriers

% OFDM modulation
txSymbols = ifft(symbols, nSubcarriers);     % IFFT per OFDM symbol

% Determine symbol padding
symbolPadLen = cyclicPrefixLen/2 + windowLen;

% Add cyclic prefix and transition region for window
% Distribute evenly at start and end of symbol
symbolPadStart = txSymbols((end-symbolPadLen+1):end,:);
symbolPadEnd = txSymbols(1:symbolPadLen,:);
txSymbolsCP = [symbolPadStart; txSymbols; symbolPadEnd];

% Create window. Should be flat outside of transition region.
window = hanning(2*windowLen+1);
window = [window(1:windowLen);
          ones(nSubcarriers+cyclicPrefixLen,1);
          window((end-windowLen+1):end)];

% Apply windowing
txSymbolsCP = txSymbolsCP.*window; % Apply windowing

% Serialize transmitted signal
txSignal = txSymbolsCP(:);

% Initialize BER array
ber = zeros(length(snrRange), 1);

% Loop over SNR values
for i = 1:length(snrRange)
    snr = snrRange(i);

    % Pass through AWGN channel
    rxSignal = awgn(txSignal, snr, 'measured');

    % Reshape received signal
    rxSymbolsCP = reshape(rxSignal, [], nSymbols);

    % Determine start and end of data payload
    symbolStart = symbolPadLen+1;
    symbolEnd = symbolStart + nSubcarriers - 1;

    % remove window and cyclic prefix
    rxSymbols = rxSymbolsCP(symbolStart:symbolEnd,:);

    % OFDM demodulation
    rxSymbols = fft(rxSymbols, nSubcarriers);

    % Extract data subcarriers
    rxSymbols = rxSymbols(dataIndices,:);

    % Demodulate received symbols
    rxBits = qamdemod(rxSymbols(:), modOrder, 'OutputType', 'bit', 'UnitAveragePower', true);

    % Calculate BER
    ber(i) = sum(bits ~= rxBits) / length(bits);
end

% Plot BER vs SNR
figure;
semilogy(snrRange, ber, '-o');
xlabel('SNR (dB)');
ylabel('Bit Error Rate (BER)');
title('BER vs. SNR for OFDM with Cyclic Prefix, Windowing, and Pilots');
grid on;

% Plot spectrum of transmitted signal
figure;
pwelch(txSignal, [], [], [], 'centered');
title('Power Spectral Density of Transmitted OFDM Signal');
xlabel('Frequency (Hz)');
ylabel('Power/Frequency (dB/Hz)');

% Plot Constellation of received symbols at a high SNR (e.g., 30 dB)
scatterplot(rxSymbols(:));
title('Received Constellation Diagram at High SNR');