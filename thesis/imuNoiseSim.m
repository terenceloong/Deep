% IMU噪声仿真

fs = 100; %Hz
N = 0.005; %deg/s/sqrt(Hz)
B = 10; %deg/h
K = 0.002; %deg/s*sqrt(Hz)

n = 5000;
a1 = randn(n,1)*N*sqrt(100);
a2 = noise_instability(n,1)*B/3600;
a3 = noise_rateRW(n,1)*K/sqrt(100);

t = (1:n)'/fs;
figure
plot(t,a1, 'LineWidth',1)
hold on
grid on
plot(t,a2, 'LineWidth',1)
plot(t,a3, 'LineWidth',3)

ax = gca;
set(ax, 'FontSize',12)
xlabel('时间/(s)')
ylabel('角速度噪声/(°/s)')
legend('角度随机游走','零偏不稳定性','速率随机游走')