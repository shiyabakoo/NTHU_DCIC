% 輸入信號
x = [1.000 - 3.000i, 3.000 - 1.000i, 1.000 - 3.000i, 1.000 - 1.000i, ...
    -1.000 + 3.000i, -1.000 - 3.000i, -1.000 + 1.000i, 3.000 + 3.000i, ...
    -3.000 + 3.000i, 1.000 + 1.000i, 1.000 - 3.000i, -3.000 - 3.000i, ...
    -1.000 - 3.000i, -1.000 - 1.000i, 3.000 - 1.000i, 3.000 - 1.000i, ...
    -3.000 - 1.000i, 1.000 + 1.000i, -3.000 - 1.000i, 1.000 - 3.000i, ...
    3.000 + 1.000i, -3.000 - 3.000i, -1.000 - 1.000i, -3.000 - 1.000i, ...
    -3.000 + 3.000i, -3.000 + 3.000i, 3.000 + 1.000i, 1.000 + 3.000i, ...
    -1.000 - 1.000i, 1.000 - 1.000i, 1.000 + 3.000i, -1.000 + 1.000i];


% 將每個元素除以根號10
x = x / sqrt(10);

% 對比序列
comparison = [-0.040 - 0.079i, 0.139 + 0.168i, 0.172 - 0.183i, 0.045 - 0.228i, ...
              0.014 + 0.173i, 0.083 + 0.251i, 0.092 - 0.208i, 0.134 + 0.024i, ...
              -0.099 + 0.020i, 0.022 - 0.001i, -0.037 + 0.084i, -0.007 - 0.013i, ...
              -0.256 - 0.078i, 0.130 - 0.107i, 0.068 + 0.015i, -0.011 + 0.093i, ...
              -0.040 + 0.040i, 0.018 - 0.116i, -0.195 - 0.103i, 0.163 + 0.107i, ...
              -0.014 - 0.134i, 0.168 - 0.071i, 0.201 - 0.236i, -0.080 - 0.025i, ...
              -0.138 + 0.099i, -0.132 - 0.129i, -0.098 - 0.035i, 0.069 - 0.169i, ...
              -0.060 + 0.118i, -0.110 - 0.152i, 0.113 - 0.124i, 0.004 + 0.053i];
% 執行IFFT
X_ifft = ifft(x);

% 將IFFT的結果輸入到FFT
X_fft = fft(X_ifft);

% 創建一個表格來顯示結果
fprintf('%-24s %-24s %-24s %-24s\n', 'input', 'ifft_result', 'comparison', 'fft_result');
fprintf('%-24s %-24s %-24s %-24s\n', '-----', '-----------', '----------', '----------');
for i = 1:length(x)
    fprintf('%-24s %-24s %-24s %-24s\n', ...
        complex2str(x(i)), ...
        complex2str(X_ifft(i)), ...
        complex2str(comparison(i)), ...
        complex2str(X_fft(i)));
end

% 比較 comparison 和 X_ifft，並顯示不一致的地方
fprintf('\nComparing IFFT result with comparison sequence:\n');
mismatch_found = false;
for i = 1:length(comparison)
    if abs(round(comparison(i), 3) - round(X_ifft(i), 3)) > 1e-3
        fprintf('Mismatch at index %d:\n', i);
        fprintf('  IFFT result: %s\n', complex2str(X_ifft(i)));
        fprintf('  Comparison:  %s\n', complex2str(comparison(i)));
        mismatch_found = true;
    end
end

if ~mismatch_found
    fprintf('Match: The comparison sequence matches the IFFT result (rounded to 3 decimal places).\n');
else
    fprintf('No Match: The comparison sequence does not fully match the IFFT result.\n');
end

% 輔助函數：將複數轉換為對齊的字符串
function str = complex2str(z)
    re = real(z);
    im = imag(z);
    if im >= 0
        str = sprintf('%7.3f + %6.3fi', re, im);
    else
        str = sprintf('%7.3f - %6.3fi', re, -im);
    end
end