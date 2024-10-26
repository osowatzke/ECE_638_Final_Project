% User configured parameters
pilotCarriers = [-21, -7, 7, 21];
pilotSymbols = [1, 1, 1, -1];
cpLen = 16;
numDataCarriers = 48;
fftSize = 64;
numSymbols = 1000;
modOrder = 4;

% Compute the number of pilot carriers
numPilotCarriers = length(pilotCarriers);

% Compute the number of sub carriers
numSubCarriers = numDataCarriers + numPilotCarriers;

% Compute the number of zero carriers
numZeroCarriers = fftSize - numSubCarriers;

% Compute random symbols
symbols = randi([0 modOrder-1], numDataCarriers, numSymbols);
symbols = qammod(symbols, modOrder);

% Compute pilots

% Determine the indices of the pilot symbols
dataCarriers = (-numSubCarriers/2):(numSubCarriers/2);
dataCarriers = dataCarriers(all(dataCarriers ~= ([pilotCarriers, 0]).'));

% Wrap data and pilot carriers to indices in range 1 to fftSize
pilotCarriers = sort(pilotCarriers + fftSize * (pilotCarriers < 0)) + 1;
dataCarriers = sort(dataCarriers + fftSize * (dataCarriers < 0)) + 1;

% Create random pilots
pnSequence = comm.PNSequence('Polynomial','z^7+z^3+1','Mask',7,...
    'InitialConditions',ones(1,7),'SamplesPerFrame',numSymbols);
p = cos(pi*pnSequence());
p = reshape(p,[],numSymbols);
pilotSymbols = repmat(pilotSymbols(:),1,numSymbols).*p;

% Populate IFFT input for symbols
ifftInput = zeros(fftSize, numSymbols);
ifftInput(dataCarriers,:) = symbols;
ifftInput(pilotCarriers,:) = pilotSymbols;

% Perform an IFFT on the symbols
ifftOutput = ifft(ifftInput);

% Add cyclic prefix
ifftOutput = [ifftOutput((end-cpLen+1):end,:); ifftOutput];

% Apply windowing