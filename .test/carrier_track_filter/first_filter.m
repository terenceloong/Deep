%% 测试一级滤波器
% 信号为匀加速
% 一级滤波用alpha-beta滤波器,用相位估计频率
% 测试不同带宽条件下的频率估计噪声
% 测试对不同加速度信号的跟踪稳态误差

clear
clc

%% 仿真时间
T = 20;
dt = 0.001;
n = T/dt;

%% 实际信号参数
a0 = 0.0; %加速度
f0 = 1;   %频率
p0 = 0;   %相位
v = 0.01; %相位测量噪声标准差

%% 本地信号参数
f = 0; %驱动频率
p = 0;  %相位

%% 滤波器系数
[alpha, beta, Bn, zeta] = alpha_beta_coef(20, v, dt);

%% 计算
output = zeros(n,2);
for k=1:n
    %----实际信号生成
    p0 = p0 + f0*dt + 0.5*a0*dt^2; %相位更新
    f0 = f0 + a0*dt; %频率更新
    %----本地信号生成
    p = p + f*dt; %相位更新
    %----一级滤波
    dp = p0 - p + randn*v; %相位差,实际减本地
    p = p + alpha*dp; %相位修正
    f = f + beta*dp; %频率修正
    %----存储
    output(k,1) = p - p0; %相位误差
    output(k,2) = f - f0; %频率误差
end