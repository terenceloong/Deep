function [Eout, Fout, Pout] = PLL2_cal(Bn, T, CN0, n)
% 计算一次二阶PLL
% Bn:环路带宽,Hz
% T:积分时间,s
% CN0:载噪比,dB·Hz
% n:计算点数
% Eout:载波鉴相器输出
% Fout:载波频率输出
% Pout:载波相位输出

[K1, K2] = order2LoopCoefD(Bn, 0.707, T); %环路系数
A = sqrt(2*T*10^(CN0/10)); %积分幅值

Eout = zeros(1,n);
Fout = zeros(1,n);
Pout = zeros(1,n);

x1 = 0; %载波频率,Hz
x2 = 0; %载波相位,周

noise = randn(1,n) + randn(1,n)*1j; %复噪声

for k=1:n
    e = -angle(A*exp(2j*pi*x2)+noise(k)) /(2*pi); %载波鉴相器输出,周
    x1 = x1 + K2*e; %更新载波频率
    x2 = x2 + (K1*e+x1)*T; %更新载波相位
    Eout(k) = e;
    Fout(k) = x1;
    Pout(k) = x2;
end

end