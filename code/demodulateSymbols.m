function bits = demodulateSymbols(symbols, modType, modOrder)
    demodulate = lookupDemodulationFunction(modType, modOrder);
    bits = demodulate(symbols);
end