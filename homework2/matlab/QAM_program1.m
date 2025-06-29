% MATLAB code to read ofdm_symbols and noise_ofdm_symbols for both 15dB and 3dB, plot waveforms,
% and use vertical dashed red lines to highlight CP and solid red lines for the last 16 data points

% Load ofdm_symbols data (same file for both 15dB and 3dB)
ofdm_data = load('QAM_ofdm_symbols.txt');

% Extract real and imaginary parts for ofdm_symbols
ofdm_real = ofdm_data(:, 1);
ofdm_imag = ofdm_data(:, 2);

% Calculate amplitude for ofdm_symbols
ofdm_amplitude = sqrt(ofdm_real.^2 + ofdm_imag.^2);

% Load noise_ofdm_symbols data for 15dB
noise_data_15db = load('QAM_noise_ofdm_symbols_15db.txt');

% Extract real and imaginary parts for noise_ofdm_symbols (15dB)
noise_real_15db = noise_data_15db(:, 1);
noise_imag_15db = noise_data_15db(:, 2);

% Calculate amplitude for noise_ofdm_symbols (15dB)
noise_amplitude_15db = sqrt(noise_real_15db.^2 + noise_imag_15db.^2);

% Load noise_ofdm_symbols data for 3dB
noise_data_3db = load('QAM_noise_ofdm_symbols_3db.txt');

% Extract real and imaginary parts for noise_ofdm_symbols (3dB)
noise_real_3db = noise_data_3db(:, 1);
noise_imag_3db = noise_data_3db(:, 2);

% Calculate amplitude for noise_ofdm_symbols (3dB)
noise_amplitude_3db = sqrt(noise_real_3db.^2 + noise_imag_3db.^2);

% Parameters
cp_length = 16;
symbol_length = 64;
cp_symbol_length = cp_length + symbol_length;

% Plot ofdm_symbols and noise_ofdm_symbols with vertical lines (dashed for CP, solid for last 16 points)
figure;

% Subplot 1: OFDM symbols (from shared ofdm_symbols.txt file)
subplot(3, 1, 1);
hold on;
plot(ofdm_amplitude);
for i = 1:floor(length(ofdm_amplitude)/cp_symbol_length)
    start_idx = (i-1) * cp_symbol_length + 1;
    end_idx = i * cp_symbol_length;
    % Add vertical dashed red lines to indicate the start and end of CP
    xline(start_idx, 'r--', 'LineWidth', 2); % Start of CP
    xline(start_idx + cp_length, 'r--', 'LineWidth', 2); % End of CP, start of symbol
    % Add text to indicate "Guard Interval" with reduced font size
    text(start_idx + cp_length/2, max(ofdm_amplitude)*0.9, 'Guard Interval', ...
         'HorizontalAlignment', 'center', 'Color', 'blue', 'FontSize', 8);
    % Add vertical solid red lines to highlight the last 16 points
    xline(end_idx - 16, 'r', 'LineWidth', 2); % Start of last 16 points
    xline(end_idx, 'r', 'LineWidth', 2); % End of symbol
end
xlabel('Sample Index');
ylabel('Amplitude');
title('OFDM Symbols Amplitude ');
grid on;
hold off;

% Subplot 2: 15dB noise-added OFDM symbols
subplot(3, 1, 2);
hold on;
plot(noise_amplitude_15db);
for i = 1:floor(length(noise_amplitude_15db)/cp_symbol_length)
    start_idx = (i-1) * cp_symbol_length + 1;
    end_idx = i * cp_symbol_length;
    % Add vertical dashed red lines to indicate the start and end of CP
    xline(start_idx, 'r--', 'LineWidth', 2); % Start of CP
    xline(start_idx + cp_length, 'r--', 'LineWidth', 2); % End of CP, start of symbol
    % Add text to indicate "Guard Interval" with reduced font size
    text(start_idx + cp_length/2, max(noise_amplitude_15db)*0.9, 'Guard Interval', ...
         'HorizontalAlignment', 'center', 'Color', 'blue', 'FontSize', 8);
    % Add vertical solid red lines to highlight the last 16 points
    xline(end_idx - 16, 'r', 'LineWidth', 2); % Start of last 16 points
    xline(end_idx, 'r', 'LineWidth', 2); % End of symbol
end
xlabel('Sample Index');
ylabel('Amplitude');
title('Noise-added OFDM Symbols (15dB) ');
grid on;
hold off;

% Subplot 3: 3dB noise-added OFDM symbols
subplot(3, 1, 3);
hold on;
plot(noise_amplitude_3db);
for i = 1:floor(length(noise_amplitude_3db)/cp_symbol_length)
    start_idx = (i-1) * cp_symbol_length + 1;
    end_idx = i * cp_symbol_length;
    % Add vertical dashed red lines to indicate the start and end of CP
    xline(start_idx, 'r--', 'LineWidth', 2); % Start of CP
    xline(start_idx + cp_length, 'r--', 'LineWidth', 2); % End of CP, start of symbol
    % Add text to indicate "Guard Interval" with reduced font size
    text(start_idx + cp_length/2, max(noise_amplitude_3db)*0.9, 'Guard Interval', ...
         'HorizontalAlignment', 'center', 'Color', 'blue', 'FontSize', 8);
    % Add vertical solid red lines to highlight the last 16 points
    xline(end_idx - 16, 'r', 'LineWidth', 2); % Start of last 16 points
    xline(end_idx, 'r', 'LineWidth', 2); % End of symbol
end
xlabel('Sample Index');
ylabel('Amplitude');
title('Noise-added OFDM Symbols (3dB) ');
grid on;
hold off;
