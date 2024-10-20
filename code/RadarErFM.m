% Parameters
c = 3e8;              % Speed of light (m/s)
fc = 24e9;            % Operating frequency (Hz)
bw = 150e6;           % Bandwidth of the chirp (Hz)
tm = 5.5e-6;          % Sweep time (s)
range_max = 200;      % Maximum range (m)
range_res = 1;        % Range resolution (m)
fs = 2*bw;            % Sampling rate (samples/second)

% Derived parameters
sweep_slope = bw / tm;        % Chirp slope
max_range_freq = 2 * range_max * sweep_slope / c; % Maximum frequency shift

% Time vector for a single chirp
t = 0:(1/fs):(tm-1/fs);

% Transmit signal (Chirp signal)
tx_sig = cos(2 * pi * (fc * t + 0.5 * sweep_slope * t.^2));

% Target parameters
r_tgt = 50;         % Actual target range (m)
v_tgt = 30;         % Target velocity (m/s)
fd_tgt = 2 * v_tgt * fc / c; % Doppler shift (Hz)

% Time delay of the received signal
tau = 2 * r_tgt / c;

% Received signal (Delayed and Doppler-shifted)
rx_sig = cos(2 * pi * (fc * (t - tau) + 0.5 * sweep_slope * (t - tau).^2) + 2*pi*fd_tgt*t);

% Mixing received and transmitted signal (beat signal)
mix_sig = tx_sig .* rx_sig;

% Range FFT
mix_sig_fft = fft(mix_sig);
freq = linspace(0, fs, length(mix_sig_fft));
range_axis = (c * freq) / (2 * sweep_slope);

% Estimate the range based on FFT peak
[~, peak_idx] = max(abs(mix_sig_fft));
estimated_range = range_axis(peak_idx);

% Calculate the error between estimated and actual range
range_error = abs(r_tgt - estimated_range);

% Error Rate Calculation
error_rate = range_error / r_tgt * 100;  % Error as a percentage of actual range

% Display results
fprintf('Actual Target Range: %.2f meters\n', r_tgt);
fprintf('Estimated Range: %.2f meters\n', estimated_range);
fprintf('Range Error: %.2f meters\n', range_error);
fprintf('Error Rate: %.2f%%\n', error_rate);

% Plot the range profile
figure;
plot(range_axis, abs(mix_sig_fft));
xlabel('Range (m)');
ylabel('Amplitude');
title('FMCW Radar Range Profile');
xlim([0 range_max]);
grid on;
