function [dataIndices, pilotIndices, zeroIndices] = ...
    getSubcarriers(varargin)
    
    args = struct(...
        'nSubcarriers',     OFDM_DEFAULT.NSUBCARRIERS,...
        'nDataCarriers',    OFDM_DEFAULT.NDATA_CARRIERS,...
        'nPilotCarriers',   OFDM_DEFAULT.NPILOT_CARRIERS,...
        'autoplacePilots',  OFDM_DEFAULT.AUTOPLACE_PILOTS,...
        'pilotCarriers',     OFDM_DEFAULT.PILOT_CARRIERS, ...
        'nullDcSubcarrier', OFDM_DEFAULT.NULL_DC_SUBCARRIER);

    for i = 1:2:length(varargin)
        args.(varargin{i}) = varargin{i+1};
    end

    % Auto-place pilots if desired
    % Will attempt to evenly space pilots
    if args.autoplacePilots
        args.pilotCarriers = placePilots(args.nDataCarriers,...
            args.nPilotCarriers, args.nullDcSubcarrier);
    end

    % Get detailed carrier counts
    nPilots = length(args.pilotCarriers);
    nZeroCarriers = args.nSubcarriers - args.nDataCarriers - nPilots;

    % Compute indices of zero carriers. 1 zero carrier at center of FFT.
    % Other zero carriers distributed at edges of FFT.
    if (nZeroCarriers > 0)
        zeroIndices = [];
        
        if args.nullDcSubcarrier
            zeroIndices = 0;
            nZeroCarriers = nZeroCarriers - 1; 
        end
        
        nZeroCarriersLow = ceil(nZeroCarriers/2);
        nZeroCarriersHigh = nZeroCarriers - nZeroCarriersLow;
        zeroIndicesLow = -args.nSubcarriers/2 + (0:(nZeroCarriersLow-1));
        zeroIndicesHigh = args.nSubcarriers/2 - (nZeroCarriersHigh:-1:1);
        zeroIndices = [zeroIndicesLow, zeroIndices, zeroIndicesHigh];
    
    % Allow user to bypass zero subcarriers
    else
        zeroIndices = [];
    end

    % Convert indices to values in range [1, N] instead of [-N/2, N/2)
    pilotIndices = sort(args.pilotCarriers + ...
        (args.pilotCarriers < 0) * args.nSubcarriers) + 1;
    zeroIndices  = sort(zeroIndices + ...
        (zeroIndices < 0) * args.nSubcarriers) + 1;

    % Determine data subcarriers indices
    dataIndices = setdiff(1:args.nSubcarriers,...
        [pilotIndices, zeroIndices]);
end