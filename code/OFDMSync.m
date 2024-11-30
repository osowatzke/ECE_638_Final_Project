%% Attempt 1
N = 128;
x = complex(randn(N,1),randn(N,1))/sqrt(2);
xRx = x;
x = [x((end-N/2+1):end); x; x(1:(N/2))];
x = x.*exp(1i*2*pi/128*(0:(length(x)-1)).');
% x = [x;x];
y = conv(x,flip(conj(xRx)));
figure(1)
clf;
hold on;
plot(abs(y))
x = [x;zeros(2*N,1)];
y = x(1:(end-N)).*conj(x((N+1):end));
y = filter(ones(1,N),1,y);
y = filter(ones(1,N)/N,1,y);
% y = [zeros(N/2,1); y];
plot(abs(y))

%% Attempt 2
s1 = randn(16,1);
s2 = randn(64,1);
s1 = repmat(s1,8,1);
s2 = [s2; s2];
preamble = [s1 s2 randn(128,2)];
preamble = [preamble((end-31):end,:); preamble];
preamble = [zeros(256,1); preamble(:)];
preamble = preamble + 10^(-80/20)*randn(size(preamble));
sync = coarseTimeSynchronizer();
frameStart = sync.run(preamble)
p1 = preamble(1:(end-16)).*conj(preamble(17:end));
p2 = preamble(17:end).*conj(preamble(17:end));
p1 = filter(ones(1,48),1,p1);
p2 = filter(ones(1,48),1,p2);
p1 = p1(49:end);
p2 = p2(49:end);
M1 = abs(p1).^2./p2.^2;
M1 = filter(ones(1,144)/144,1,M1);
figure(4)
clf;
plot(M1);
% a = 1/8;
% fastPwr = filter(a,[1 -(1-a)],M1);
% a = 1/128;
% slowPwr = filter(a,[1 -(1-a)],M1);
% figure(4)
% clf;
% plot(fastPwr);
% hold on;
% plot(slowPwr);
% plot(db(fastPwr) - db(slowPwr))
% 
% M1 = filter(ones(1,64)/(64),1,M1);
% M1diff = M1(1:(end-1)) - M1(2:end);
% M1 = filter(ones(48,1),1,M1);
% h = [1, zeros(1,15)];
% h = repmat(h,1,3);
% M1 = filter(h,1,M1);
% p1 = preamble(1:(end-32)).*conj(preamble(33:end));
% p2 = preamble(1:(end-32)).*conj(preamble(1:(end-32)));
% p1 = filter(ones(1,32),1,p1);
% p2 = filter(ones(1,32),1,p2);
% M2 = abs(p1).^2./p2.^2;
% Mdiff = M1(1:(end-16)) - M2;
figure(1)
clf;
% p1 = filter(ones(1,32)/64,1,p1);
plot(p1);
figure(6)
clf;
plot(p2);
figure(2)
clf;
% hold on;
plot(M1)
% plot(M2)
figure(3)
clf;
plot(Mdiff);
figure(4)
% Mdiff = filter(ones(1,16)/16,1,Mdiff);
% figure(3)
% clf;
% plot(Mdiff);
% M = filter(ones(1,9*16),1,M);
Mdiff = filter([1 -1], 1, M1);
figure(11)
clf;
plot(Mdiff)
