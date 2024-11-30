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

%% PSLR (Measurement #1)

radar = FMCWRadar(...
    'targetRange', 50,...
    'targetVelocity', 0,...
    'SNR_dB', 100,...
    'rangeOSR', 16,...
    'PSLRIgnoreGates', 0,...
    'sampleRate', sampleRate,...
    'PRF', PRF,...
    'numPulses', numPulses);

radar.run();

%% PSLR (Measurement #2)

radar = FMCWRadar(...
    'targetRange', 50,...
    'targetVelocity', 0,...
    'SNR_dB', 100,...
    'fastTimeWindow', @(x)chebwin(x,80),... % 80 dB Chebyshev window
    'slowTimeWindow', @(x)chebwin(x,80),... % 80 dB Chebyshev window
    'rangeOSR', 16,...
    'PSLRIgnoreGates', 1,...
    'sampleRate', sampleRate,...
    'PRF', PRF,...
    'numPulses', numPulses);

radar.run();

%% PSLR (Measurement #3)

radar = FMCWRadar(...
    'targetRange', 50,...
    'targetVelocity', 0,...
    'SNR_dB', 100,...
    'fastTimeWindow', @(x)taylorwin(x),...
    'slowTimeWindow', @(x)taylorwin(x),...
    'rangeOSR', 16,...
    'PSLRIgnoreGates', 1,...
    'sampleRate', sampleRate,...
    'PRF', PRF,...
    'numPulses', numPulses);

radar.run();

%% Ambiguous Range

% Create radar object
radar = FMCWRadar(...
    'targetRange', 1250,...
    'targetVelocity', 0, ...
    'fastTimeWindow', @(x)chebwin(x,80),... % 80 dB Chebyshev window
    'slowTimeWindow', @(x)chebwin(x,80),... % 80 dB Chebyshev window
    'sampleRate', sampleRate,...
    'PRF', PRF,...
    'numPulses', numPulses);

% Run radar
radar.run();

%% Ambiguous Velocity

% Create radar object
radar = FMCWRadar(...
    'targetRange', 100,...
    'targetVelocity', 250, ...
    'fastTimeWindow', @(x)chebwin(x,80),... % 80 dB Chebyshev window
    'slowTimeWindow', @(x)chebwin(x,80),... % 80 dB Chebyshev window
    'sampleRate', sampleRate,...
    'PRF', PRF,...
    'numPulses', numPulses);

% Run radar
radar.run();

%% SNR measurement

% Create radar object
radar = FMCWRadar(...
    'targetRange', 50*rgSize,...
    'targetVelocity', 0, ...
    'SNR_dB', 20,...
    'fastTimeWindow', @(x)chebwin(x,80),... % 80 dB Chebyshev window
    'slowTimeWindow', @(x)chebwin(x,80),... % 80 dB Chebyshev window
    'sampleRate', sampleRate,...
    'PRF', PRF,...
    'numPulses', numPulses);

% Run radar
radar.run();