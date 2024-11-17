% MATLAB OFDM Simulation with Cyclic Prefix, Pilots, Zeroing, Windowing

% Parameters
nSubcarriers = 64;        % Number of OFDM subcarriers
nDataSubCarriers = 48;    % Number of OFDM data subcarriers
nSymbols = 100;           % Number of OFDM symbols
cyclicPrefixLen = 16;     % Length of cyclic prefix
windowLen = 4;            % Length of window
snrRange = 0:2:20;        % SNR range in dB
pilotIndices = [-21, -7, 7, 21]; % 802.11a pilots

% QPSK Modulation
modOrder = 4;
bitsPerSymbol = log2(modOrder);

% Get detailed carrier counts
nPilots = length(pilotIndices);
nZeroCarriers = nSubcarriers - nDataSubCarriers - nPilots;

% Compute indices of zero carriers. 1 zero carrier at center of FFT.
% Other zero carriers distributed at edges of FFT.
if (nDataSubCarriers < nSubcarriers)
    nZeroCarriersLow = ceil((nZeroCarriers-1)/2);
    nZeroCarriersHigh = nZeroCarriers - nZeroCarriersLow - 1;
    zeroIndicesLow = -nSubcarriers/2 + (0:(nZeroCarriersLow-1));
    zeroIndicesHigh = nSubcarriers/2 - (nZeroCarriersHigh:-1:1);
    zeroIndices = [zeroIndicesLow, 0, zeroIndicesHigh];

% Allow user to bypass zero subcarriers
else
    zeroIndices = [];
end

% Convert indices to values in range [1, N] instead of [-N/2, N/2)
pilotIndices = sort(pilotIndices + (pilotIndices < 0) * nSubcarriers) + 1;
zeroIndices  = sort(zeroIndices + (zeroIndices < 0) * nSubcarriers) + 1;

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

% Plot Constellation of received symbols at a high SNR (e.g., 30 dB)
scatterplot(rxSymbols(:));
title('Received Constellation Diagram at High SNR');