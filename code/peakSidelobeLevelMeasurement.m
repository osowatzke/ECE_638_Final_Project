c = physconst('lightspeed');
B = 300e6;
rgSize = c/(2*B);
numRangeGates = 256;
fftSize = numRangeGates*16;

x = exp(1i*2*pi*50*(0:numRangeGates-1)/numRangeGates);
Fx = fft(x, fftSize);