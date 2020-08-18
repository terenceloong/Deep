% 测试角加速度估计器
% 需要调出合适的带宽

[K1, K2] = order2LoopCoefA(8, 0.707);

n = size(imu,1); %总点数
dt = 0.01; %时间间隔
X = imu(:,3); %输入
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

t = (1:n)*dt;
figure %原始角速度与滤波后的角速度
plot(t, X)
hold on
grid on
plot(t, Y)
set(gca, 'XLim',[0,t(end)])
legend('原始角速度输出','滤波后的角速度输出')

figure %估计的角加速度
plot(t, V)
grid on
set(gca, 'XLim',[0,t(end)])
title('估计的角加速度')

figure %原始角速度与角加速度积分值
plot(t, X)
hold on
grid on
plot(t, cumsum(V)*dt)
set(gca, 'XLim',[0,t(end)])
legend('原始角速度输出','估计的角加速度积分值')