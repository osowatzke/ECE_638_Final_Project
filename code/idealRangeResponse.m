%% Ideal Frequency Response
% Number of subcarriers
N = 64;

% Frequency Axis
k = 0:(N-1);
k = k - N/2;

% Determine Ideal Matched Filter Response
% 1 at all non-zero subcarriers
Y = zeros(size(k));
Y(-26 <= k & k <= 26) = 1;
Y(k == 0) = 0;

% Plot Ideal Matched Filter Response
w = 2*pi*k/N;
figure(1)
clf;
plot(w, Y, 'LineWidth',1.5);
grid on;
title('Ideal Matched Filter Response')
xlabel('Normalized Frequency (\times pi rad/sample)')
ylabel('Magnitude');

%% Get range response
% Determine the Range Response
fftSize = N;
Ypad = [zeros(1, fftSize/2-N/2), Y, zeros(1, fftSize/2-N/2)];
Yshift = ifftshift(Ypad);
y = ifft(Yshift, fftSize);
y = y/max(abs(y));
n = (0:(length(y)-1));
figure(2)
clf;
plot(n,db(y),'LineWidth',1.5);
grid on;
xlim([n(1) n(end)])
xlabel('Sample')
ylabel('Magnitude (dB)')
title('Ideal Range Response');

%% Get range response w/ zero-padding
% Determine the Range Response
fftSize = 16*N;
Ypad = [zeros(1, fftSize/2-N/2), Y, zeros(1, fftSize/2-N/2)];
Yshift = ifftshift(Ypad);
y = ifft(Yshift, fftSize);
y = y/max(abs(y));
n = (0:(length(y)-1));
figure(3)
clf;
plot(n,db(y),'LineWidth',1.5);
grid on;
xlim([n(1) n(end)])
xlabel('Sample')
ylabel('Magnitude (dB)')
title('Ideal Range Response');

%% Get frequency response with window
% Get window for all non-zero subcarriers
win = chebwin(53,80);
padSize = N - length(win);
win = [zeros(ceil(padSize/2),1); win; zeros(floor(padSize/2),1)].';

% Apply window
Y = Y.*win;

% Plot Ideal Matched Filter Response
w = 2*pi*k/N;
figure(4)
clf;
plot(w, Y, 'LineWidth',1.5);
grid on;
title('Ideal Matched Filter Response')
xlabel('Normalized Frequency (\times pi rad/sample)')
ylabel('Magnitude');

%% Get range response w/ zero-padding
% Determine the Range Response
fftSize = 16*N;
Ypad = [zeros(1, fftSize/2-N/2), Y, zeros(1, fftSize/2-N/2)];
Yshift = ifftshift(Ypad);
y = ifft(Yshift, fftSize);
y = y/max(abs(y));
n = (0:(length(y)-1));
figure(5)
clf;
plot(n,db(y),'LineWidth',1.5);
grid on;
xlim([n(1) n(end)])
xlabel('Sample')
ylabel('Magnitude (dB)')
title('Ideal Range Response');

%% Ideal Range Response w/o Zero Subcarrier
% Number of subcarriers
N = 64;

% Frequency Axis
k = 0:(N-1);
k = k - N/2;

% Determine Ideal Matched Filter Response
% 1 at all non-zero subcarriers
Y = zeros(size(k));
Y(-26 <= k & k <= 26) = 1;

% Get window for all non-zero subcarriers
win = chebwin(53,80);
padSize = N - length(win);
win = [zeros(ceil(padSize/2),1); win; zeros(floor(padSize/2),1)].';

% Apply window
Y = Y.*win;

%% Get range response
% Determine the Range Response
fftSize = 16*N;
Ypad = [zeros(1, fftSize/2-N/2), Y, zeros(1, fftSize/2-N/2)];
Yshift = ifftshift(Ypad);
y = ifft(Yshift, fftSize);
y = y/max(abs(y));
n = (0:(length(y)-1));
figure(6)
clf;
plot(n,db(y),'LineWidth',1.5);
grid on;
xlim([n(1) n(end)])
xlabel('Sample')
ylabel('Magnitude (dB)')
title('Ideal Range Response');