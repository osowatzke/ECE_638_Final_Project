%% Run OFDM Model using 802.11a pilots and AWGN channel
o = ofdmModel();
o.run();

%% Run OFDM Model using 802.11a pilots and Rayleigh channel
o = ofdmModel(...
    'enRayleighFading', true,...
    'enPerfectChanEst', true,...
    'eqAlgorithm', 'mmse');
o.run();