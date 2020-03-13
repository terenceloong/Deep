function [alpha, Bn] = alpha_coef(w, v, dt)
% 计算alpha滤波器系数
% w:过程噪声标准差
% v:量测噪声标准差
% dt:离散时间间隔
% alpha:相位修正系数,p(k+1)=p(k)+alpha*dp
% https://en.wikipedia.org/wiki/Alpha_beta_filter

% 计算系数
% 根据参考文献<The tracking index: A generalized parameter for α-β and α-β-γ target trackers>
% 函数输入的w实际上是公式中的w*(dt/2)
% 所以需将函数输入的w除以(dt/2),变成公式中使用的w
w = w/(dt/2);
lamda = w/v*dt^2;
alpha = (-lamda^2 + sqrt(lamda^4+16*lamda^2)) / 8;

% 这个公式是解黎卡提方程推出来的,计算结果与上面的相同
% P的稳态解:P^2/(P+v^2) = w^2*dt^2 = Q
% P = (w^2*dt^2 + w^2*dt^2*sqrt(1+4*v^2/(w^2*dt^2))) / 2;
% alpha = P/(P+v^2) = Q/P = w^2*dt^2/P
% 参见<卡尔曼滤波与组合导航原理(第2版)>159页
% alpha = 2 / (1+sqrt(1+4*v^2/(w^2*dt^2)));

% 计算带宽
% <PhaseLock Techniques> P130
K = alpha/dt; %比例系数
Bn = K/4; %Hz

end