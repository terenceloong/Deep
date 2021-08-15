function [K1, K2, K3] = order3LoopCoefA(Bn)
% 连续三阶锁相环系数
% Bn:环路噪声带宽,Hz
% 参见<Springer Handbook of Global Navigation Satellite Systems> P420

w0 = 1.275*Bn;
a3 = 1.1;
b3 = 2.4;

K1 = b3*w0;
K2 = a3*w0^2;
K3 = w0^3;

end