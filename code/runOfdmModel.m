%% Run OFDM Model using 802.11a pilots and AWGN channel
o = ofdmModel('nSymbols', 1e5);
o.run();

%% Run OFDM Model using 802.11a pilots and Rayleigh channel
o = ofdmModel(...
    'nSymbols', 1e5,...
    'enRayleighFading', true,...
    'eqAlgorithm', 'mmse');
o.run();