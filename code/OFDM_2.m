% Parameters
numSubcarriers = 64;        % Number of OFDM subcarriers
cpLen = 16;                 % Length of cyclic prefix
modOrder = 4;               % Modulation order (QPSK, 4-QAM)
numSymbols = 1000;          % Number of OFDM symbols
snrRange = 0:2:30;          % SNR values in dB

% Generate random bits
bits = randi([0 modOrder-1], numSubcarriers*numSymbols, 1);

% Modulation (QPSK)
modSymbols = qammod(bits, modOrder, 'UnitAveragePower', true);

% Reshape into OFDM symbols
ofdmSymbols = reshape(modSymbols, numSubcarriers, numSymbols);

% IFFT operation to convert frequency domain to time domain
txSignal = ifft(ofdmSymbols, numSubcarriers);

% Add Cyclic Prefix
txSignalWithCP = [txSignal(end-cpLen+1:end, :); txSignal];

% Flatten for transmission
txFlattened = txSignalWithCP(:);

% Pre-allocate BER array
ber = zeros(1, length(snrRange));

% Loop over different SNR values
for snrIdx = 1:length(snrRange)
    snr = snrRange(snrIdx);

    % Transmit through an AWGN channel
    rxFlattened = awgn(txFlattened, snr, 'measured');
    
    % Reshape back to OFDM symbol size
    rxSignalWithCP = reshape(rxFlattened, numSubcarriers+cpLen, numSymbols);
    
    % Remove Cyclic Prefix
    rxSignal = rxSignalWithCP(cpLen+1:end, :);
    
    % FFT operation to convert back to frequency domain
    rxSymbols = fft(rxSignal, numSubcarriers);
    
    % Demodulation (QPSK)
    rxBits = qamdemod(rxSymbols, modOrder, 'UnitAveragePower', true);
    
    % Reshape the received bits into a single vector
    rxBits = rxBits(:);
    
    % Calculate Bit Error Rate (BER)
    [numErrors, ber(snrIdx)] = biterr(bits, rxBits);
end

% Plot SNR vs BER
figure;
semilogy(snrRange, ber, '-o');
xlabel('SNR (dB)');
ylabel('Bit Error Rate (BER)');
title('SNR vs BER for OFDM Communication');
grid on;

% Display results for a selected SNR
selectedSNR = 20;
fprintf('At SNR = %d dB:\n', selectedSNR);
fprintf('BER = %.6f\n', ber(snrRange == selectedSNR));

% Plot Constellation Diagrams
figure;
subplot(1, 2, 1);
scatterplot(modSymbols(:));
title('Transmitted QPSK Symbols');

subplot(1, 2, 2);
scatterplot(rxSymbols(:));
title('Received QPSK Symbols (at SNR = 20 dB)');
