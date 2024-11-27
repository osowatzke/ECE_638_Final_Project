function symbols = modulateBits(bits, modType, modOrder)
    modulate = lookupModulationFunction(modType, modOrder);
    symbols = modulate(bits);
end