% Function demodulates a sequence of symbols with desired modulation
% type and modulation order
%
% Inputs:
%   symbols     Array of symbols
%   modType     Name of modulation type. Must be either 'qam' or 'psk'
%   modOrder    Modulation order (# of points in constellation)
%
% Outputs:
%   bits        Array of bits
%
function bits = demodulateSymbols(symbols, modType, modOrder)
    if strcmpi(modType, 'psk')
        bits = pskdemod(symbols, modOrder, 'OutputType', 'bit');
    elseif strcmpi(modType, 'qam')
        bits = qamdemod(symbols, modOrder, 'OutputType', 'bit',...
            'UnitAveragePower', true);
    else
        error('Unsupported modulation type. Select from {''QAM'',''PSK''}');
    end
end