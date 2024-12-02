%% OFDM Radar Range Resolution Measurement
c = physconst('lightspeed');
sampleRate = 10e6;
rgSize = c/(2*sampleRate);

radar = ofdmRadar(...
    'targetRange', [8*rgSize, 10*rgSize],...
    'targetVelocity', [0 0],...
    'SNR_dB', [100 100],...
    'rangeOSR', 16,...
    'nDataCarriers', 49,...
    'nullDcSubcarrier', false,...
    'fastTimeWin',@(x)rectwin(x),...
    'slowTimeWin',@(x)rectwin(x));
radar.run();

%% OFDM Radar Range Resolution Measurement (Part #2)
c = physconst('lightspeed');
sampleRate = 10e6;
rgSize = c/(2*sampleRate);

radar = ofdmRadar(...
    'targetRange', 8*rgSize,...
    'targetVelocity', 0,...
    'SNR_dB', 100,...
    'rangeOSR', 256,...
    'nDataCarriers', 49,...
    'nullDcSubcarrier', false,...
    'fastTimeWin',@(x)rectwin(x),...
    'slowTimeWin',@(x)rectwin(x));
radar.run();

%% OFDM Radar PSLR Measurement
radar = ofdmRadar(...
    'targetRange', 50,...
    'targetVelocity', 0,...
    'SNR_dB', 100,...
    'nullDcSubcarrier', false);
radar.run();

%% OFDM Radar PSLR Measurement w/ DC Subcarrier
radar = ofdmRadar(...
    'targetRange', 50,...
    'targetVelocity', 0,...
    'SNR_dB', 100,...
    'nDataCarriers', 49,...
    'nullDcSubcarrier', false);
radar.run();

%% OFDM Radar PSLR Measurement
f = 5.9e9;
c = physconst('lightspeed');
lambda = c/f;
sampleRate = 10e6;
PRI = 84/sampleRate;
PRF = 1/PRI;
unambigVelocity = PRF*lambda/4;
targetVelocity = -100:10:100; %(-128:4:127)*unambigVelocity/128;
PSLR_dB = zeros(size(targetVelocity));

for i = 1:length(PSLR_dB)
    radar = ofdmRadar(...
        'nDataCarriers', 49,...
        'targetVelocity', targetVelocity(i),...
        'nullDcSubcarrier', false, ...
        'plotResults', false,...
        'SNR_dB', 200,...
        'numPulses', 256);
    radar.run();
    PSLR_dB(i) = radar.measurePSLR();
end

figure(1)
clf;
plot(targetVelocity, PSLR_dB, 'LineWidth', 1.5);
grid on;

 % Label Plot
title('Peak Sidelobe Ratio vs Velocity')
xlabel('Velocity (m/s)')
ylabel('PSLR (dB)')

%% OFDM Radar PSLR Measurement
f = 5.9e9;
c = physconst('lightspeed');
lambda = c/f;
sampleRate = 10e6;
PRI = 84/sampleRate;
unambigRange = c*PRI/2;
targetRange = linspace(0,unambigRange);
PSLR_dB = zeros(size(targetRange));

for i = 1:length(PSLR_dB)
    radar = ofdmRadar(...
        'nDataCarriers', 49,...
        'targetRange', targetRange(i),...
        'targetVelocity', 0,...
        'nullDcSubcarrier', false, ...
        'plotResults', false,...
        'SNR_dB', 200,...
        'numPulses', 256);
    radar.run();
    PSLR_dB(i) = radar.measurePSLR();
end

figure(1)
clf;
plot(targetRange, PSLR_dB, 'LineWidth', 1.5);
xlim([targetRange(1) targetRange(end)])
grid on;

% Determine the maximum range with acceptable performance
c = physconst('lightspeed');
Rmax = c*16/sampleRate/2;
line(Rmax*ones(1,2), ylim, 'color', 'red',...
    'LineWidth',1.5, 'LineStyle', '--')

% Label Plot
legend('R_{max}','PSLR(dB)');
title('Peak Sidelobe Ratio vs Range')
xlabel('Range (m)')
ylabel('PSLR (dB)')

%% OFDM Radar (Target at Large Range);
radar = ofdmRadar(...
    'nDataCarriers', 49,...
    'nullDcSubcarrier', false,...
    'targetRange', 50);
radar.run();

%% OFDM Radar (Target at Even Larger Range);
radar = ofdmRadar(...
    'nDataCarriers', 49,...
    'nullDcSubcarrier', false,...
    'targetRange', 1000);
radar.run();

%% OFDM Radar Improved Parameters
radar = ofdmRadar(...
    'carrierFreq', 77e9,...
    'targetRange', 50,...
    'targetVelocity', 0,...
    'rangeOSR', 256,...
    'SNR_dB', 100,...
    'sampleRate', 320e6,...
    'nSubcarriers', 32*64,...
    'nDataCarriers', 32*48+1,...
    'nPilotCarriers', 32*4,...
    'cyclicPrefixLen', 32*16,...
    'autoplacePilots', true,...
    'nullDcSubcarrier', false,...
    'numPulses', 16,...
    'fastTimeWin',@(x)rectwin(x),...
    'slowTimeWin',@(x)rectwin(x));
radar.run();

%% OFDM Radar Improved Parameters
radar = ofdmRadar(...
    'carrierFreq', 77e9,...
    'targetRange', 50,...
    'targetVelocity', 50,...
    'sampleRate', 320e6,...
    'nSubcarriers', 32*64,...
    'nDataCarriers', 32*48+1,...
    'nPilotCarriers', 32*4,...
    'cyclicPrefixLen', 32*16,...
    'autoplacePilots', true,...
    'nullDcSubcarrier', false,...
    'numPulses', 256);
radar.run();