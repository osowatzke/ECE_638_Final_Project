%% FMCW Radar without window

% Create radar object
radar = FMCWRadar(...
    'targetRange', 50,...
    'targetVelocity', 50,...
    'numPulses', 128);

% Run radar
radar.run();

%% FMCW Radar with fast and slow-time windows

% Create radar object
radar = FMCWRadar(...
    'targetRange', 50,...
    'targetVelocity', 50, ...
    'fastTimeWindow', @(x)chebwin(x,80),... % 80 dB Chebyshev window
    'slowTimeWindow', @(x)chebwin(x,80),... % 80 dB Chebyshev window
    'numPulses', 128);

% Run radar
radar.run();