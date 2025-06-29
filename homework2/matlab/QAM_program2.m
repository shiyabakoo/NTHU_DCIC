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
axis([-8 8 -8 8]); % Set x and y axis limits to -8 to 8
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
axis([-8 8 -8 8]); % Set x and y axis limits to -8 to 8
axis equal;
