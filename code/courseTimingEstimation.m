SNR_dB = 20;
% M = 64;
% N = 1000;
rng(0);
N = 256;
x = ifft(randn(N,16))*sqrt(N);
% x = [ifft(upsample(randn(N/2,1),2)), x];
preamble = complex(randn(N/4,1),randn(N/4,1))/sqrt(2);
preamble = preamble.*[1 1 -1 -1];
preamble = preamble(:);
x = [preamble, x];
x = [x;x(1:(N/4),:)];
% x = 10^(SNR_dB/20)*1/sqrt(2)*complex(randn(M,1),randn(M,1)); %zadoffChuSeq(1,M);
% x = 10^(SNR_dB/20)*complex(randn(M,1),randn(M,1));
% x = repmat(x,1,4).*[-1,1,-1,-1];
% x = [x; -conj(x); x; x];
% x = [x;-x;x;x;x(1:16)];
x = x(:);
% x = x.*exp(1i*2*pi/1024*(0:(length(x)-1)).');
rawPwr = abs(x).^2;
a = 0.01;
avgPwr = filter(a,[1 -(1-a)], rawPwr);
figure(16)
clf;
plot(avgPwr)
x = [zeros(128,1); x];
% x = [x; zeros(N-2*M-16,1)];
% x = circshift(x,M);
% x = [zeros(64,1); x(1:(end-64))];
n = 10^(-SNR_dB/20)/sqrt(2)*complex(randn(size(x)),randn(size(x)));
y = x + n;
% y = x + 1/sqrt(2)*complex(randn(N,1),randn(N,1));
M = N/4;
y1 = y((M+1):end).*conj(y(1:(end-M)));
% y2 = y(1:(end-M)).*conj(y(1:(end-M)));
y2 = y((M+1):end).*conj(y((M+1):end));
y1 = filter(ones(1,M),1,y1);
y2 = filter(ones(1,M),1,y2);
y1 = filter([1 zeros(1,2*M-1) 1],1,y1);
y2 = filter([1 zeros(1,2*M-1) 1],1,y2);
% y1 = filter([1 zeros(1,M-1) -1], [1 -1], y1);
% y2 = filter([1 zeros(1,M-1) -1], [1 -1], y2);
M = abs(y1).^2./abs(y2).^2;
M = filter(ones(1,N/4),1,M);
figure(1)
clf;
plot(abs(y1))
figure(2);
clf;
plot(abs(y2));
figure(3)
clf;
plot(abs(M))
Mdiff = M(2:end)-M(1:(end-1));
figure(10)
clf;
plot(Mdiff)
% MPwr = Mdif
rawPwr = M.*conj(M);
a = 1/4;
fastPwr = filter(a,[1 -(1-a)],rawPwr);
a = 1/32;
slowPwr = filter(a,[1 -(1-a)],rawPwr);
figure(4)
clf;
% plot(rawPwr)
hold on;
plot(fastPwr)
plot(slowPwr)
figure(5)
clf;
plot(db(fastPwr) - db(slowPwr));
% hold on;
% plot(slowPwr);
% plot(M)