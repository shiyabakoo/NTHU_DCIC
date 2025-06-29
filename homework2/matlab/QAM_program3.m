% Load the data from the file
data = load('QAM_ber_vs_snr.txt');

% Separate the columns into SNR and BER
SNR = data(:, 1);
BER = data(:, 2);

% Replace zero BER values with a very small value for plotting
BER(BER == 0) = 1e-12;

% Plot the BER versus SNR
figure;
semilogy(SNR, BER, 'o-', 'LineWidth', 2);
grid on;
xlabel('SNR (dB)');
ylabel('BER');
title('BER vs SNR for QPSK Modulation over AWGN Channel');

% Set x-axis limits to show SNR up to 24
xlim([min(SNR), 24]);

% Set x-axis ticks to be multiples of 3
xticks(0:3:24);

% Annotate each point with its BER value in larger red font
for i = 1:length(SNR)
    text(SNR(i), BER(i), sprintf('%.1e', BER(i)), ...
        'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right', ...
        'FontSize', 14);  % Font size increased to 14 and color set to red
end
