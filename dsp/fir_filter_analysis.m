% =========================================================================
% 6-Tap Moving Average FIR Filter: Mathematical & Spectral Analysis
% Author: Julio Tito (Rutgers University - ECE)
% Target: Verilog Hardware Golden Verification & Fixed-Point Comparison
% =========================================================================

clear; clc; close all;

%% 1. Filter Specifications
N = 6;                          % Number of filter taps
Fs = 100e6;                     % System Clock Frequency: 100 MHz
b = (1/8) * ones(1, N);         % Normalized impulse response h[n] (divide by 8)
a = 1;                          % FIR denominator (all-zero filter)

%% 2. Discrete Transfer Function H(z)
% H(z) = 1/8 * (1 + z^-1 + z^-2 + z^-3 + z^-4 + z^-5)
% H(z) = 1/8 * (1 - z^-6) / (1 - z^-1)
[H, f] = freqz(b, a, 1024, Fs);
mag_db = 20 * log10(abs(H));
phase_deg = unwrap(angle(H)) * 180 / pi;

%% 3. Plot Frequency Response (Bode Plot)
figure('Name', '6-Tap FIR Filter Frequency Response', 'Color', 'w');

% Magnitude Response
subplot(2, 1, 1);
plot(f / 1e6, mag_db, 'LineWidth', 2, 'Color', [0, 0.447, 0.741]);
grid on;
title('Magnitude Response |H(e^{j\omega})| (Normalized)');
xlabel('Frequency (MHz)');
ylabel('Magnitude (dB)');
xlim([0, Fs/(2*1e6)]);
ylim([-45, 0]);
yline(-2.5, '--r', 'DC Gain = -2.5 dB (6/8)', 'LabelHorizontalAlignment', 'left');
xline(Fs/6 / 1e6, ':k', 'Transmission Zero (Null 1: 16.67 MHz)');
xline(Fs/3 / 1e6, ':k', 'Transmission Zero (Null 2: 33.33 MHz)');

% Phase Response
subplot(2, 1, 2);
plot(f / 1e6, phase_deg, 'LineWidth', 2, 'Color', [0.85, 0.325, 0.098]);
grid on;
title('Linear Phase Response \angle H(e^{j\omega})');
xlabel('Frequency (MHz)');
ylabel('Phase (Degrees)');
xlim([0, Fs/(2*1e6)]);

%% 4. Golden Test Vector Generation (Ramp Stimulus)
x_ramp = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160];
y_golden = zeros(1, length(x_ramp));
delay_line = zeros(1, N);

for n = 1:length(x_ramp)
    % Shift delay line
    delay_line = [x_ramp(n), delay_line(1:end-1)];
    
    % Sum & power-of-two bit shift
    accum = sum(delay_line);
    y_golden(n) = bitshift(accum, -3); % Equivalent to >> 3
end

fprintf('====================================================\n');
fprintf('MATLAB GOLDEN TEST VECTORS FOR VERILOG TESTBENCH\n');
fprintf('====================================================\n');
for n = 1:length(x_ramp)
    fprintf('Sample %2d | Input: %3d | Golden Filtered Output: %3d\n', ...
            n, x_ramp(n), y_golden(n));
end
fprintf('====================================================\n');
