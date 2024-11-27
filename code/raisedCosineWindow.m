% Function generates a raised cosine window for OFDM modulation
% 
% Inputs:
%   nSubcarriers        Number of OFDM subcarriers
%   cyclicPrefixLen     Cyclic prefix length
%   windowLen           Window length (ramp up/down time at start
%                       and end of signal). Ramp up/down time appended
%                       to symbol with cyclic prefix.
%
% Outputs:
%   window              Raised cosine window.
%
function window = raisedCosineWindow(nSubcarriers,...
    cyclicPrefixLen, windowLen)

    % Generate hanning window
    window = hanning(2*windowLen + 1);

    % Extend ones at middle of window to match the length of
    % symbol with cyclic prefix
    window = [window(1:windowLen);
        ones(nSubcarriers + cyclicPrefixLen, 1);
        window((end-windowLen+1):end)];
end