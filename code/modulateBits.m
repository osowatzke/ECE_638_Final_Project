% Function modulates a sequence of bits with desired modulation
% type and modulation order
%
% Inputs:
%   bits        Array of bits
%   modType     Name of modulation type. Must be either 'qam' or 'psk'
%   modOrder    Modulation order (# of points in constellation)
%
% Outputs:
%   symbols     Array of symbols
%
function symbols = modulateBits(bits, modType, modOrder)
    if strcmpi(modType, 'psk')
        symbols = pskmod(bits, modOrder, 'InputType', 'bit');
    elseif strcmpi(modType, 'qam')
        symbols = qammod(bits, modOrder, 'InputType', 'bit',...
            'UnitAveragePower', true);
    else
        error('Unsupported modulation type. Select from {''QAM'',''PSK''}');
    end
end