function [K1, K2] = order2LoopCoefD(Bn, zeta, T)
% 离散二阶环路系数
% Bn:环路噪声带宽,Hz,loop noise bandwidth
% zeta:阻尼系数,damping ratio
% T:采样时间步长,s
% 参见<Software Defined Radio using MATLAB Simulink and the RTL-SDR> P601

theta = Bn*T / (zeta+0.25/zeta); %D.49

K1 = 4*zeta*theta / (1+2*zeta*theta+theta^2) / T; %D.50
K2 = 4*theta^2 / (1+2*zeta*theta+theta^2) / T; %D.51
% 最后除的T来源于NCO,离散模型中没有考虑时间步长,需要在这补上

end