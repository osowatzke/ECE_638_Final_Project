%% OFDM Radar w/ Default Parameters
radar = ofdmRadar(...
    'nDataCarriers', 49,...
    'nullDcSubcarrier', false);
radar.run();

%% OFDM Radar (Target at Large Range);
radar = ofdmRadar(...
    'nDataCarriers', 49,...
    'nullDcSubcarrier', false,...
    'targetRange', 500);
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
    'targetRange', 200,...
    'targetVelocity', 50,...
    'sampleRate', 200e6,...
    'nSubcarriers', 16*64,...
    'nDataCarriers', 16*48+1,...
    'nPilotCarriers', 16*4,...
    'autoplacePilots', true,...
    'nullDcSubcarrier', false,...
    'numPulses', 128);
radar.run();