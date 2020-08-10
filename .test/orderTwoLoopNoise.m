% 计算二阶环输出噪声
% 2Hz带宽，输出噪声比例为0.07 (sqrt(2/500),1000Hz采样频率)
% 25Hz带宽，输出噪声比例为0.22 (sqrt(25/500),1000Hz采样频率) 6.15速度比例
% 等效噪声带宽为半扇

[K1, K2] = orderTwoLoopCoef(25, 0.707, 1);

n = 100*1000; %总点数
dt = 0.001; %时间间隔
X = randn(n,1); %输入
Y = zeros(n,1); %输出
V = zeros(n,1); %积分器

x1 = 0; %控制器积分输出
x2 = 0; %总积分输出
for k=1:n
    e = X(k) - x2;
    x1 = x1 + K2*e*dt;
    x2 = x2 + (K1*e+x1)*dt;
    Y(k) = x2;
    V(k) = x1;
end

figure
plot((1:n)*dt, X)
hold on
plot((1:n)*dt, Y)
figure
plot((1:n)*dt, V)

disp(std(Y)) %输出噪声标准差
disp(std(V))

function [K1, K2] = orderTwoLoopCoef(LBW, zeta, k)
% 二阶环路系数
%   Inputs:
%       LBW           - Loop noise bandwidth
%       zeta          - Damping ratio
%       k             - Loop gain
%
%   Outputs:
%       K1, K2        - Loop filter coefficients 

% Solve natural frequency
Wn = LBW*8*zeta / (4*zeta^2 + 1);

% solve for K1 & K2
K1 = 2*zeta*Wn / k;
K2 = Wn^2 / k;

end