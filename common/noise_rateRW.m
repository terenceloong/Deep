function N = noise_rateRW(n, m)
% 生成速率随机游走噪声
% n:数据个数
% m:数据维数
% 参考Matlab imuSensor

N = zeros(n,m);
y = zeros(1,m);
for k=1:n
    y = y + randn(1,m);
    N(k,:) = y;
end

end