% Input parameters
M = 256;
sampleRate = 10e6;
SNR_dB = -20:2:40;

% Dependent parameters
bitsPerSymbol = log2(M);

% Compute shannon capacity
SNR = 10.^(SNR_dB/10);
B = sampleRate;
C = B*log2(1+SNR);

% Compute theoretical rates
ber = berawgn(SNR_dB-10*log10(2),'qam',M);
H = @(p)(-(p.*log2(p) + (1-p).*log2(1-p)));
R = sampleRate*bitsPerSymbol*(1-H(ber));

figure(1)
clf;
plot(SNR_dB,C);
hold on;
plot(SNR_dB,R);
