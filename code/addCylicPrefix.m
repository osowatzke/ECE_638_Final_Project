function ofdmSymbolsWithPrefix = addCylicPrefix(ofdmSymbols, varargin)
    
    args = struct(...
        'cyclicPrefixLen', 16,...
        'windowLen', 4);

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