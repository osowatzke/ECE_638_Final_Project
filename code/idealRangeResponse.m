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

% Determine the Range Response
fftSize = 1024;
Y = [zeros(1, fftSize/2-N/2), Y, zeros(1, fftSize/2-N/2)];
Y = ifftshift(Y);
y = ifft(Y, fftSize);
y = y/max(abs(y));
figure(2)
clf;
plot(db(y),'LineWidth',1.5);
xlabel('Sample')
ylabel('Magnitude (dB)')
title('Ideal Range Response');

% % Apply a window
% Y = ifftshift(Y);
% % win = chebwin(26,80);
% % win = [zeros(6,1); win; 0; win; zeros(5,1)];
% win = chebwin(53,80);
% win = [zeros(6,1); win; zeros(5,1)];
% win = ifftshift(win).';
% Y = Y.*win;
% Y = ifft(Y, );
% plot(db(Y))
