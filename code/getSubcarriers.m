function [dataIndices, pilotIndices, zeroIndices] = ...
    getSubcarriers(varargin)
    
    args = struct(...
        'nSubcarriers', 64,...
        'nDataCarriers', 48,...
        'pilotIndices', [-21, -7, 7, 21]);

    for i = 1:2:length(varargin)
        args.(varargin{i}) = varargin{i+1};
    end

    % Get detailed carrier counts
    nPilots = length(args.pilotIndices);
    nZeroCarriers = args.nSubcarriers - args.nDataCarriers - nPilots;

    % Compute indices of zero carriers. 1 zero carrier at center of FFT.
    % Other zero carriers distributed at edges of FFT.
    if (nZeroCarriers > 0)
        nZeroCarriersLow = ceil((nZeroCarriers-1)/2);
        nZeroCarriersHigh = nZeroCarriers - nZeroCarriersLow - 1;
        zeroIndicesLow = -args.nSubcarriers/2 + (0:(nZeroCarriersLow-1));
        zeroIndicesHigh = args.nSubcarriers/2 - (nZeroCarriersHigh:-1:1);
        zeroIndices = [zeroIndicesLow, 0, zeroIndicesHigh];
    
    % Allow user to bypass zero subcarriers
    else
        zeroIndices = [];
    end

    % Convert indices to values in range [1, N] instead of [-N/2, N/2)
    pilotIndices = sort(args.pilotIndices + ...
        (args.pilotIndices < 0) * args.nSubcarriers) + 1;
    zeroIndices  = sort(zeroIndices + ...
        (zeroIndices < 0) * args.nSubcarriers) + 1;

    % Determine data subcarriers indices
    dataIndices = setdiff(1:args.nSubcarriers,...
        [pilotIndices, zeroIndices]);
end