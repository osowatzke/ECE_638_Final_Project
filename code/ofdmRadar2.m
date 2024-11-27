modType = 'qam';
modOrder = 4;
nSubcarriers = 64;
nDataCarriers = 48;
pilotIndices = [-21 -7 7 21];
useDcSubcarrier = true;
cyclicPrefixLen = 16;
windowLen = 4;

numPulses = 128;
sampleRate = 10e6;
carrierFreq = 77e9;
range = 200;
velocity = 25;
c = 3e8;
delay = 2*range/c;
delay = round(delay*sampleRate);
lambda = c/carrierFreq;
fd = 2*velocity/lambda;
fd = fd/sampleRate;
windowFun = @(x)chebwin(x, 80);
SNR_dB = 40;

modulator = ofdmModulator(...
    'modType',         modType,...        
    'modOrder',        modOrder,...       
    'nSubcarriers',    nSubcarriers,...   
    'nDataCarriers',   nDataCarriers,...  
    'pilotIndices',    pilotIndices,...   
    'useDcSubcarrier', useDcSubcarrier,...
    'cyclicPrefixLen', cyclicPrefixLen,...
    'windowLen',       windowLen);

numBits = log2(modOrder)*nDataCarriers*numPulses;
bits = randi([0 1], numBits, 1);
bits = reshape(bits, [], numPulses);

txSignal = modulator.run(bits);

Fmf = zeros(size(modulator.symbols));
Fmf(modulator.dataIndices,:) = 1./modulator.dataSymbols;
Fmf(modulator.pilotIndices,:) = 1./modulator.pilotSymbols;

m = modulator.cyclicPrefixLen/2;
k = (0:(size(Fmf,1)-1)).';
Fmf = Fmf.*exp(-1i*2*pi*m*k/nSubcarriers);

rxSignal = filter([zeros(1,delay-1),1], 1, txSignal(:));
rxSignal = awgn(rxSignal, SNR_dB, 'measured');
rxSignal = rxSignal.*exp(1i*2*pi*fd*(0:(length(rxSignal)-1)).');
rxSignal = reshape(rxSignal, [], numPulses);

symbolStart = modulator.cyclicPrefixLen + modulator.windowLen + 1;
symbolEnd = size(rxSignal,1) - modulator.windowLen;
rxSignal = rxSignal(symbolStart:symbolEnd, :);
Frx = fft(rxSignal);

Fmfout = Frx.*Fmf;

nActiveCarriers = nDataCarriers + length(pilotIndices);
if useDcSubcarrier
    windowLen = nActiveCarriers;
else
    windowLen = nActiveCarriers + 1;
end
window = windowFun(windowLen);
zeroLen = nSubcarriers - windowLen;
window = [window; zeros(zeroLen, 1)];
window = circshift(window, ceil(zeroLen/2));
window = fftshift(window);

Fmfout = Fmfout.*window;
mfout = ifft(Fmfout);

win = chebwin(numPulses,80).';
rdm = fft(mfout.*win, [], 2);

figure(1)
clf;
plot(db(mfout(:,1)))

figure(2)
clf;
imagesc(db(fftshift(rdm,2)));

