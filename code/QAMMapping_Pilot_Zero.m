% Parameters
numSubcarriers = 64;         % Total number of OFDM subcarriers
cpLen = 16;                  % Length of Cyclic Prefix
modOrder = 4;                % Modulation order (QPSK, 4-QAM)
numSymbols = 1000;           % Number of OFDM symbols
pilotInterval = 8;           % Interval for pilot carriers
numPilots = numSubcarriers/pilotInterval;  % Number of pilot carriers
snrRange = 0:2:30;           % SNR values in dB

% Zero carriers (at the edges to avoid interference)
zeroCarrierIdx = [1, numSubcarriers];  % Example: placing zeros at the edge subcarriers

% Generate random bits
bits = randi([0 modOrder-1], (numSubcarriers-numPilots-2)*numSymbols, 1); % Exclude pilots and zero carriers

% QPSK modulation
modSymbols = qammod(bits, modOrder, 'UnitAveragePower', true);

% Initialize OFDM symbol grid with pilots and zero carriers
ofdmSymbols = zeros(numSubcarriers, numSymbols);

% Insert modulated data into subcarriers excluding pilots and zeros
dataCarrierIdx = setdiff(1:numSubcarriers, [1:numPilots:numSubcarriers, zeroCarrierIdx]);
ofdmSymbols(dataCarrierIdx, :) = reshape(modSymbols, length(dataCarrierIdx), numSymbols);

% Insert pilot symbols (e.g., all ones or random QPSK symbols)
pilotSymbols = ones(numPilots, numSymbols);  % Pilot symbol could also be randomized
ofdmSymbols(1:numPilots:numSubcarriers, :) = pilotSymbols;

% IFFT operation to convert frequency domain symbols to time domain
txSignal = ifft(ofdmSymbols, numSubcarriers);

% Add Cyclic Prefix
txSignalWithCP = [txSignal(end-cpLen+1:end, :); txSignal];

% Flatten for transmission
txFlattened = txSignalWithCP(:);

% Pre-allocate BER array
ber = zeros(1, length(snrRange));

% Loop over different SNR values for BER calculation
for snrIdx = 1:length(snrRange)
    snr = snrRange(snrIdx);
    
    % Transmit through AWGN channel
    rxFlattened = awgn(txFlattened, snr, 'measured');
    
    % Reshape received signal back to OFDM symbols with Cyclic Prefix
    rxSignalWithCP = reshape(rxFlattened, numSubcarriers+cpLen, numSymbols);
    
    % Remove Cyclic Prefix
    rxSignal = rxSignalWithCP(cpLen+1:end, :);
    
    % FFT operation to convert back to frequency domain
    rxSymbols = fft(rxSignal, numSubcarriers);
    
    % Channel estimation using pilot symbols (simple example)
    estimatedChannel = mean(rxSymbols(1:numPilots:numSubcarriers, :) ./ pilotSymbols, 2);
    equalizedSymbols = rxSymbols ./ estimatedChannel;
    
    % Extract the data subcarriers (excluding pilots and zeros)
    rxDataSymbols = equalizedSymbols(dataCarrierIdx, :);
    
    % Demodulate the received symbols
    rxBits = qamdemod(rxDataSymbols, modOrder, 'UnitAveragePower', true);
    
    % Reshape received bits into a single vector
    rxBits = rxBits(:);
    
    % Calculate Bit Error Rate (BER)
    [numErrors, ber(snrIdx)] = biterr(bits, rxBits);
end

% Plot SNR vs BER
figure;
semilogy(snrRange, ber, '-o');
xlabel('SNR (dB)');
ylabel('Bit Error Rate (BER)');
title('SNR vs BER for OFDM with Pilots and Zero Carriers');
grid on;

% Plot Constellation of received symbols at a high SNR (e.g., 30 dB)
figure;
scatterplot(rxDataSymbols(:));
title('Received Constellation Diagram at High SNR');
