function [txSignal, ofdmSymbols] = ofdmModulation(bits, varargin)
    
    args = struct(...
        'modType', 'qam',...
        'modOrder', 4,...
        'nSubcarriers', 64,...
        'nDataCarriers', 48,...
        'pilotIndices', [-21 -7 7 21],...
        'useDcSubcarrier', false,...
        'cyclicPrefixLen', 16,...
        'windowLen', 4);

    for i = 1:2:length(varargin)
        args.(varargin{i}) = varargin{i+1};
    end

    if mod(args.nDataCarriers, args.nDataCarriers) ~= 0
        error(['Expected Number of Data Symbols (%d) to be a ',...
            'Multiple of the Number of Data Carriers (%d)'],...
            args.nDataCarriers, args.nDataCarriers);
    end

    dataSymbols = modulateBits(bits, args.modType, args.modOrder);

    [dataIndices, pilotIndices] = getSubcarriers(...
        'nSubcarriers', args.nSubcarriers,...
        'nDataCarriers', args.nDataCarriers,...
        'pilotIndices', args.pilotIndices,...
        'useDcSubcarrier', args.useDcSubcarrier);

    dataSymbols = reshape(dataSymbols, args.nDataCarriers, []);

    % Allocate empty array for OFDM symbols
    ofdmSymbols = zeros(args.nSubcarriers, size(dataSymbols, 2));

    % Insert Data Carriers
    ofdmSymbols(dataIndices, :) = dataSymbols;

    % Create pseudo-random pilots
    numPilots = length(pilotIndices);
    s = RandStream('mt19937ar','Seed',0);
    pilotSymbols = randi(s,[0 1], numPilots, size(ofdmSymbols, 2));
    pilots = cos(pi*pilotSymbols);

    % Insert Pilot Carriers
    ofdmSymbols(pilotIndices, :) = pilots;

    % Perform IFFT for modulation
    ofdmSymbols = ifft(ofdmSymbols);

    % Add cyclic prefix
    ofdmSymbolsWithPrefix = addCylicPrefix(ofdmSymbols,...
        'cyclicPrefixLen', args.cyclicPrefixLen,...
        'windowLen', args.windowLen);

    % Create raised cosine window
    window = raisedCosineWindow(args.nSubcarriers,...
        args.cyclicPrefixLen, args.windowLen);

    % Apply Window
    txSignal = ofdmSymbolsWithPrefix.*window;
end