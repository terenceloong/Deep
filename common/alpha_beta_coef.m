function [alpha, beta, Bn, zeta] = alpha_beta_coef(w, v, dt)
% 计算alpha-beta滤波器系数
% alpha:相位修正系数,p(k+1)=p(k)+alpha*dp
% beta:频率修正系数,v(k+1)=v(k)+beta*dp
% https://en.wikipedia.org/wiki/Alpha_beta_filter

% 计算系数
lamda = w/v*dt^2;
r = (4 + lamda - sqrt(8*lamda+lamda^2)) / 4;
alpha = 1-r^2;
beta = (2*(2-alpha) - 4*sqrt(1-alpha)) / dt;

% 计算带宽
K1 = alpha/dt; %比例系数
K2 = beta/dt; %积分系数
Wn = sqrt(K2);
zeta = K1/2/Wn;
Bn = Wn*(4*zeta^2+1) / (8*zeta); %Hz

end