% Load the QPSK symbols for SNR = 3dB
data_3db = load('rx_qpsk_symbols_3db.txt');
real_3db = data_3db(:,1);
imag_3db = data_3db(:,2);

% Load the QPSK symbols for SNR = 15dB
data_15db = load('rx_qpsk_symbols_15db.txt');
real_15db = data_15db(:,1);
imag_15db = data_15db(:,2);

% Ideal QPSK constellation points (+-0.707, +-0.707)
ideal_constellation = [1.0 1.0; 1.0 -1.0; -1.0 1.0; -1.0 -1.0];

% Plot constellation for SNR = 3dB
figure;
scatter(real_3db, imag_3db, 'o', 'b', 'filled'); % Plot received QPSK symbols with circles
hold on;
scatter(ideal_constellation(:,1), ideal_constellation(:,2), 100, 'x', 'r', 'LineWidth', 2); % Plot ideal QPSK points with X markers
xline(0, 'k', 'LineWidth', 1.5); % Plot x=0 solid line
yline(0, 'k', 'LineWidth', 1.5); % Plot y=0 solid line
title('Constellation Diagram for SNR = 3dB');
xlabel('In-phase');
ylabel('Quadrature');
legend('Received Symbols', 'Ideal Constellation', 'Location', 'Best');
grid on;
axis equal;

% Plot constellation for SNR = 15dB
figure;
scatter(real_15db, imag_15db, 'o', 'b', 'filled'); % Plot received QPSK symbols with circles
hold on;
scatter(ideal_constellation(:,1), ideal_constellation(:,2), 100, 'x', 'r', 'LineWidth', 2); % Plot ideal QPSK points with X markers
xline(0, 'k', 'LineWidth', 1.5); % Plot x=0 solid line
yline(0, 'k', 'LineWidth', 1.5); % Plot y=0 solid line
title('Constellation Diagram for SNR = 15dB');
xlabel('In-phase');
ylabel('Quadrature');
legend('Received Symbols', 'Ideal Constellation', 'Location', 'Best');
grid on;
axis equal;
