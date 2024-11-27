function demodulate = lookupDemodulationFunction(modType, modOrder)
    if strcmpi(modType, 'psk')
        demodulate = @(x) pskdemod(x, modOrder, 'OutputType', 'bit');
    elseif strcmp(modType, 'qam')
        demodulate = @(x) qamdemod(x, modOrder, 'OutputType', 'bit',...
            'UnitAveragePower', true);
    else
        error('Unsupported modulation type. Select from {''QAM'',''PSK''}');
    end
end