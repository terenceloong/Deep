function N = noise_instability(n, m)
% 生成零偏不稳定性噪声
% n:数据个数
% m:数据维数
% 参考Matlab imuSensor

N = zeros(n,m);
y = zeros(1,m);
for k=1:n
    y = 0.5*y + randn(1,m);
    N(k,:) = y;
end

end