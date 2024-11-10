% MATLAB OFDM Simulation with Cyclic Prefix, Pilots, Zeroing, Windowing

% Parameters
nSubcarriers = 64;        % Number of OFDM subcarriers
nSymbols = 100;           % Number of OFDM symbols
cyclicPrefixLen = 16;     % Length of cyclic prefix
snrRange = 0:2:20;        % SNR range in dB
pilotIndices = 1:8:nSubcarriers;  % Pilot every 8 subcarriers
zeroIndices = [1:5, (nSubcarriers-4):nSubcarriers];  % Zeroed subcarriers

% QPSK Modulation
modOrder = 4;
bitsPerSymbol = log2(modOrder);

% Generate random bits
bits = randi([0 1], nSymbols * nSubcarriers * bitsPerSymbol, 1);

% Reshape bits into QPSK symbols
symbols = qammod(bits, modOrder, 'InputType', 'bit', 'UnitAveragePower', true);
symbols = reshape(symbols, nSubcarriers, nSymbols);

% Insert pilots and zeroing
symbols(pilotIndices, :) = 1;         % Pilots set to 1
symbols(zeroIndices, :) = 0;          % Zeroed subcarriers

% Initialize BER array
ber = zeros(length(snrRange), 1);

% Loop over SNR values
for i = 1:length(snrRange)
    snr = snrRange(i);

    % OFDM modulation
    txSymbols = ifft(symbols, nSubcarriers);     % IFFT per OFDM symbol
    window = hamming(nSubcarriers);              % Hamming window
    txSymbols = txSymbols .* window;             % Apply windowing

    % Add cyclic prefix
    txSymbolsCP = [txSymbols(end-cyclicPrefixLen+1:end, :); txSymbols];

    % Serialize transmitted signal
    txSignal = txSymbolsCP(:);

    % Pass through AWGN channel
    rxSignal = awgn(txSignal, snr, 'measured');

    % Reshape received signal
    rxSymbolsCP = reshape(rxSignal, nSubcarriers + cyclicPrefixLen, nSymbols);
    rxSymbols = rxSymbolsCP(cyclicPrefixLen+1:end, :);  % Remove cyclic prefix
    rxSymbols = rxSymbols ./ window;                    % Remove window

    % OFDM demodulation
    rxSymbols = fft(rxSymbols, nSubcarriers);

    % Channel estimation and equalization (Assume known channel)
    rxSymbols(pilotIndices, :) = rxSymbols(pilotIndices, :) ./ abs(rxSymbols(pilotIndices, :));

    % Zeroed subcarriers
    rxSymbols(zeroIndices, :) = 0;

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
figure;
scatterplot(rxSymbols(:));
title('Received Constellation Diagram at High SNR');