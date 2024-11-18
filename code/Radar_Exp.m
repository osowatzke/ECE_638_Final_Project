% Radar Parameters
fc = 77e9;                 % Carrier frequency (Hz)
c = 3e8;                   % Speed of light (m/s)
bw = 200e6;                % Bandwidth (Hz)
chirp_duration = 10e-6;    % Chirp duration (s)
sweep_slope = bw / chirp_duration; % Chirp slope (Hz/s)
fs = 2 * bw;               % Sampling frequency (Hz)
lambda = c / fc;           % Wavelength (m)
num_chirps = 8;            % Number of chirp pulses

% Target Parameters
range_target = 50;         % Target range (m)
velocity_target = 30;      % Target velocity (m/s)
fd = 2 * velocity_target / lambda; % Doppler frequency (Hz)
time_delay = 2 * range_target / c; % Round-trip delay (s)

% Time Vectors
t = 0:1/fs:chirp_duration - 1/fs;    % Single chirp time
pri = chirp_duration + 1e-6;         % Pulse Repetition Interval (PRI)
T = 0:pri:(num_chirps - 1) * pri;    % Chirp start times

% Generate Transmitted Signal (Exponential Form)
tx_sig = zeros(length(t), num_chirps);
rx_sig = zeros(length(t), num_chirps);
for k = 1:num_chirps
    % Transmitted chirp in exponential form
    tx_sig(:, k) = exp(1j * 2 * pi * (fc * t + 0.5 * sweep_slope * t.^2));
    
    % Simulate Received Signal (with delay and Doppler)
    current_t = t - time_delay;
    rx_sig(:, k) = exp(1j * 2 * pi * (fc * current_t + ...
                     0.5 * sweep_slope * current_t.^2 + fd * t)) + ...
                   0.01 * (randn(size(t)) + 1j * randn(size(t))); % Add noise
end

% Matched Filtering and Range Estimation
mf_out = zeros(2 * length(t) - 1, num_chirps);
lags = (-length(t) + 1:length(t) - 1) / fs; % Lag vector
range_estimates = zeros(1, num_chirps);

for k = 1:num_chirps
    % Cross-correlation
    mf_out(:,k) = xcorr(rx_sig(:,k), tx_sig(:,k));
    [~, max_idx] = max(abs(mf_out(k, :)));
    estimated_delay = lags(max_idx); % Delay corresponding to peak
    range_estimates(k) = c * estimated_delay / 2; % Range estimate
end

% Doppler Processing via FFT
fft_out = fftshift(fft(range_estimates));
doppler_axis = (-num_chirps/2:num_chirps/2-1) / (num_chirps * pri); % Doppler axis
[~, doppler_idx] = max(abs(fft_out));
estimated_doppler = doppler_axis(doppler_idx); % Doppler frequency
estimated_velocity = estimated_doppler * lambda / 2; % Velocity estimate

% Display Results
disp(['Estimated Ranges (m): ', num2str(range_estimates)]);
disp(['Estimated Velocity (m/s): ', num2str(estimated_velocity)]);

% Plot Transmitted and Received Signals
figure;
hold on;
for k = 1:num_chirps
    subplot(num_chirps, 1, k);
    plot(t, real(tx_sig(:,k)), 'b', 'DisplayName', 'Transmitted Signal');
    hold on;
    plot(t, real(rx_sig(:,k)), 'r', 'DisplayName', 'Received Signal');
    title(['Chirp ', num2str(k)]);
    xlabel('Time (s)');
    ylabel('Amplitude');
    legend;
end

% Plot Matched Filter Output (Range Estimation)
figure;
plot(lags, abs(mf_out(:,1)), 'b', 'DisplayName', 'Matched Filter Output');
title('Matched Filter Output (Range Estimation)');
xlabel('Lag (s)');
ylabel('Amplitude');
legend;

% Plot Doppler FFT Output (Velocity Estimation)
figure;
plot(doppler_axis, abs(fft_out), 'r', 'DisplayName', 'Doppler FFT Output');
title('Doppler FFT Output (Velocity Estimation)');
xlabel('Doppler Frequency (Hz)');
ylabel('Amplitude');
legend;
