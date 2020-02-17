function [K1, K2] = order2LoopCoefA(Bn, zeta)
% 模拟二阶环路系数
% Bn:环路噪声带宽,Hz,loop noise bandwidth
% zeta:阻尼系数,damping ratio
% 参见<Software Defined Radio using MATLAB Simulink and the RTL-SDR> D2附录

Wn = Bn*8*zeta / (4*zeta^2 + 1); %D.48

K1 = 2*zeta*Wn; %D.24上面那句话
K2 = Wn^2;

end