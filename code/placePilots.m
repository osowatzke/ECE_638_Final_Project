% Function places pilot carriers
%
% Inputs
%   nDataCarriers       Number of Data Carriers
%   nPilots             Number of Pilot Carriers
%   nullDcSubcarrier    Specifies whether DC subcarrier is null
%
% Outputs:
%   pilotCarriers       Pilot Carriers
%
function pilotCarriers = placePilots(nDataCarriers, nPilotCarriers, nullDcSubcarrier)
    
    % Determine number of nonzero subcarriers
    nSubcarriers = nDataCarriers + nPilotCarriers;

    % If DC subcarrier is null
    if (nullDcSubcarrier)

        % Ensure even number of pilots and subcarriers
        if mod(nPilotCarriers,2) ~= 0
            error('Expected an even number of pilots');
        end

        if mod(nSubcarriers,2) ~= 0
            error('Expected an even number of subcarriers');
        end

        % Determine number of positive pilots and subcarriers
        nSubcarriers = nSubcarriers/2;
        nPilotCarriers = nPilotCarriers/2;
    end

    % Create edges for nPilot bins
    % Offset by -0.5 to account for integer sampling
    edges = linspace(0, nSubcarriers, nPilotCarriers + 1) - 0.5;

    % Determine the size of each bin
    binSize = edges(2) - edges(1);

    % Place the pilot carriers in the center of each bin
    pilotCarriers = edges(1:(end-1)) + binSize/2;

    % If DC subcarrier is null, we are only doing this for one
    % half of the subcarriers
    if (nullDcSubcarrier)

        % Determine pilot indices. Add one to account for 0 being skipped
        pilotCarriers = ceil(pilotCarriers) + 1;

        % Negative pilots are mirror of positive pilots
        pilotCarriers = [-flip(pilotCarriers), pilotCarriers];

    % DC subcarrier is not null
    else

        % Account for negative carriers
        pilotCarriers = pilotCarriers - nSubcarriers/2;

        % Quantize pilot positions
        pilotCarriers = ceil(pilotCarriers);
    end
    
end
