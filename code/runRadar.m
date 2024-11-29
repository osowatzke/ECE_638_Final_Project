%% Common parameters
c = physconst('lightspeed');
sampleRate = 300e6;
rgSize = c/(2*sampleRate);
PRF = 200e3;
numPulses = 256;

%% Range resolution
radar = FMCWRadar(...
    'targetRange', [49*rgSize, 51*rgSize],...
    'SNR_dB', [40, 40],...
    'targetVelocity', [0, 0],...
    'sampleRate', sampleRate,...
    'PRF', PRF,...
    'numPulses', numPulses);

radar.run();

%% PLSR (Measurement #1)
radar = FMCWRadar(...
    'targetRange', 100*rgSize,...
    'targetVelocity', 0,...
    'SNR_dB', 100,...
    'PSLRIgnoreGates', 0,...
    'sampleRate', sampleRate,...
    'PRF', PRF,...
    'numPulses', numPulses);

radar.run();

%% PLSR (Measurement #2)
radar = FMCWRadar(...
    'targetRange', 100.5*rgSize,...
    'targetVelocity', 0,...
    'SNR_dB', 100,...
    'PSLRIgnoreGates', 0,...
    'sampleRate', sampleRate,...
    'PRF', PRF,...
    'numPulses', numPulses);

radar.run();

%% PSLR (Measurement #3)

radar = FMCWRadar(...
    'targetRange', 50,...
    'targetVelocity', 0,...
    'rangeOSR', 16,...
    'PSLRIgnoreGates', 0,...
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