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
plot(SNR_dB, C, 'LineWidth', 1.5);
grid on;
xlabel('SNR (dB)')
ylabel('Capacity (bps)')
title('OFDM 802.11p Capacity')


