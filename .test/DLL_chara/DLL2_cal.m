function [Eout, Fout, Pout] = DLL2_cal(Bn, T, CN0, n)
% 计算一次二阶DLL
% Bn:环路带宽,Hz
% T:积分时间,s
% CN0:载噪比,dB·Hz
% n:计算点数
% Eout:码鉴相器输出
% Fout:码频率输出
% Pout:码相位输出

[K1, K2] = order2LoopCoefD(Bn, 0.707, T); %环路系数
A = sqrt(2*T*10^(CN0/10)); %积分幅值

Eout = zeros(1,n);
Fout = zeros(1,n);
Pout = zeros(1,n);

x1 = 0; %码频率,Hz
x2 = 0; %码相位,码片

noiseE = (randn(1,n) + randn(1,n)*1j) / sqrt(2); %超前路复噪声,因为噪声相关,所以幅值除sqrt(2)
noiseL = (randn(1,n) + randn(1,n)*1j) / sqrt(2); %滞后路复噪声

for k=1:n
    SE = abs(A*(1-(x2+0.3))+noiseE(k)); %超前路幅值
    SL = abs(A*(1+(x2-0.3))+noiseL(k)); %滞后路幅值
    e = 0.7 * (SE-SL) / (SE+SL); %码鉴相器输出
%     SE = abs(A*(1-1.5*(x2+0.3))+noiseE(k)); %超前路幅值
%     SL = abs(A*(1+1.5*(x2-0.3))+noiseL(k)); %滞后路幅值
%     e = (11/30) * (SE-SL) / (SE+SL) / 2; %码鉴相器输出
    x1 = x1 + K2*e; %更新码频率
    x2 = x2 + (K1*e+x1)*T; %更新码相位
    Eout(k) = e;
    Fout(k) = x1;
    Pout(k) = x2;
end

end