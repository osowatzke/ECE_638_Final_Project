function modulate = lookupModulationFunction(modType, modOrder)
    if strcmpi(modType, 'psk')
        modulate = @(x) pskmod(x, modOrder, 'InputType', 'bit');
    elseif strcmp(modType, 'qam')
        modulate = @(x) qammod(x, modOrder, 'InputType', 'bit',...
            'UnitAveragePower', true);
    else
        error('Unsupported modulation type. Select from {''QAM'',''PSK''}');
    end
end