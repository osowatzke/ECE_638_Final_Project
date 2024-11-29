%% Range resolution
c = physconst('lightspeed');
B = 300e6;
rgSize = c/(2*B);

radar = FMCWRadar(...
    'targetRange', [49*rgSize, 51*rgSize],...
    'SNR_dB', [40, 40],...
    'targetVelocity', [0, 0],...
    'sampleRate', 300e6,...
    'PRF', 200e3,...
    'numPulses', 256);

radar.run();

%% No window

% Create radar object
radar = FMCWRadar(...
    'targetRange', 50,...
    'targetVelocity', 100,...
    'numPulses', 128);

% Run radar
radar.run();

%% Both Fast and slow-time windows

% Create radar object
radar = FMCWRadar(...
    'targetRange', 50,...
    'targetVelocity', 100, ...
    'fastTimeWindow', @(x)chebwin(x,80),... % 80 dB Chebyshev window
    'slowTimeWindow', @(x)chebwin(x,80),... % 80 dB Chebyshev window
    'numPulses', 128);

% Run radar
radar.run();

%% Ambiguous Range

% Create radar object
radar = FMCWRadar(...
    'targetRange', 350,...
    'targetVelocity', 100, ...
    'fastTimeWindow', @(x)chebwin(x,80),... % 80 dB Chebyshev window
    'slowTimeWindow', @(x)chebwin(x,80),... % 80 dB Chebyshev window
    'numPulses', 128);

% Run radar
radar.run();

%% Ambiguous Velocity

% Create radar object
radar = FMCWRadar(...
    'targetRange', 50,...
    'targetVelocity', 750, ...
    'fastTimeWindow', @(x)chebwin(x,80),... % 80 dB Chebyshev window
    'slowTimeWindow', @(x)chebwin(x,80),... % 80 dB Chebyshev window
    'numPulses', 128);

% Run radar
radar.run();

%% PSLR measurement

% Create radar object
radar = FMCWRadar(...
    'targetRange', 50,...
    'targetVelocity', 750, ...
    'SNR_dB', 150,...
    'fastTimeWindow', @(x)chebwin(x,80),... % 80 dB Chebyshev window
    'slowTimeWindow', @(x)chebwin(x,80),... % 80 dB Chebyshev window
    'numPulses', 128);

% Run radar
radar.run();