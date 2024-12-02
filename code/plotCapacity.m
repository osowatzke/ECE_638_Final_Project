%% 802.11p capacity
% OFDM 802.11p Parameters
B = 10e6;
nSubcarriers = 64;
nDataCarriers = 48;
nPilots = 4;

% Range of SNR to consider
SNR_dB = 0:2:20;

% Convert SNR to linear units
SNR = 10.^(SNR_dB/10);

% Determine the effective SNR and Bandwidth
nActiveCarriers = nDataCarriers + nPilots;
SNR_eff = SNR*nSubcarriers/nActiveCarriers;
B_eff = B*nActiveCarriers/nSubcarriers;

% Determine capacity
C = B_eff.*log2(1 + SNR_eff);

% Plot the Capacity
figure(1)
clf;
plot(SNR_dB, C, 'LineWidth', 1.5);
grid on;
xlabel('SNR (dB)')
ylabel('Capacity (bps)')
title('OFDM 802.11p Capacity')

%% Capacity against bandwidth
SNR_dB = 0:4:20;
SNR = 10.^(SNR_dB/10);
B = 10e6;
P_N0 = B*SNR;

B = (10e6:10e6:500e6).';
C = B.*log2(1 + P_N0./B);

figure(2)
clf;
plot(B,C, 'LineWidth', 1.5)
grid on;
legend(strcat('SNR = ', num2str(SNR_dB.'), 'dB'), 'location', 'northwest')
xlabel('Bandwidth (Hz)');
ylabel('Capacity')
title('Capacity vs Bandwidth')
