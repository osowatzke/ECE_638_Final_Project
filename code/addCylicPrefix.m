% Function adds cyclic prefix to OFDM symbols
% Syntax:
%
%   Y = addCylicPrefix(x) appends default cyclic prefix length
%   to OFDM symbols.
%
%   Y = addCylicPrefix(X, Name, Value) allows the user to specify
%   additional key-value arguments given below:
%
%   'cyclicPrefixLen'   Cyclic prefix length
%   'windowLen'         Window length (appended to both ends of symbol)
% 
function ofdmSymbolsWithPrefix = addCylicPrefix(ofdmSymbols, varargin)
    
    args = struct(...
        'cyclicPrefixLen', OFDM_DEFAULT.CYCLIC_PREFIX_LEN,...
        'windowLen',       OFDM_DEFAULT.WINDOW_LEN);

    for i = 1:2:length(varargin)
        args.(varargin{i}) = varargin{i+1};
    end

    % Determine padding on either side of signal
    symbolPadLen = args.cyclicPrefixLen/2 + args.windowLen;

    % Apply cyclic prefix to either side of symbols
    ofdmSymbolsStart = ofdmSymbols(1:symbolPadLen, :);
    ofdmSymbolsEnd = ofdmSymbols((end-symbolPadLen+1):end, :);
    ofdmSymbolsWithPrefix = [
        ofdmSymbolsEnd; 
        ofdmSymbols; 
        ofdmSymbolsStart];
end