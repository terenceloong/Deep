% 不同惯导延时下,惯性辅助二阶环路相位伯德图
clear
clc

Bn = 25; %带宽
[K1, K2] = order2LoopCoefA(Bn, sqrt(0.5)); %系数

H0 = tf([K1,K2], [1,K1,K2]);

a = 1/0.003; %时延的倒数
H1 = tf([K1+a,K1*a+K2,K2*a], [1,K1+a,K1*a+K2,K2*a]);
a = 1/0.006;
H2 = tf([K1+a,K1*a+K2,K2*a], [1,K1+a,K1*a+K2,K2*a]);
a = 1/0.01;
H3 = tf([K1+a,K1*a+K2,K2*a], [1,K1+a,K1*a+K2,K2*a]);

% 计算频率相应
w = {1e-1*2*pi, 1e3*2*pi}; %计算频率范围,rad/s
[mag0,phase0,wout0] = bode(H0, w);
mag0 = reshape(mag0,size(mag0,3),1); %排成列向量
phase0 = reshape(phase0,size(phase0,3),1);
wout0 = wout0/2/pi;
[mag1,phase1,wout1] = bode(H1, w);
mag1 = reshape(mag1,size(mag1,3),1);
phase1 = reshape(phase1,size(phase1,3),1);
wout1 = wout1/2/pi;
[mag2,phase2,wout2] = bode(H2, w);
mag2 = reshape(mag2,size(mag2,3),1);
phase2 = reshape(phase2,size(phase2,3),1);
wout2 = wout2/2/pi;
[mag3,phase3,wout3] = bode(H3, w);
mag3 = reshape(mag3,size(mag3,3),1);
phase3 = reshape(phase3,size(phase3,3),1);
wout3 = wout3/2/pi;

% 画图
figure

subplot(2,1,1)
semilogx(wout0, 20*log10(mag0), 'LineWidth',1)
grid on
hold on
semilogx(wout1, 20*log10(mag1), 'LineWidth',1)
semilogx(wout2, 20*log10(mag2), 'LineWidth',1)
semilogx(wout3, 20*log10(mag3), 'LineWidth',1)
ax = gca;
set(ax, 'FontSize',12)
set(ax, 'YLim',[-32,5])
ylabel('幅值/(dB)')
legend('普通二阶环','延迟3ms','延迟6ms','延迟10ms', 'Location','southwest')

subplot(2,1,2)
semilogx(wout0, phase0, 'LineWidth',1)
grid on
hold on
semilogx(wout1, phase1, 'LineWidth',1)
semilogx(wout2, phase2, 'LineWidth',1)
semilogx(wout3, phase3, 'LineWidth',1)
ax = gca;
set(ax, 'FontSize',12)
set(ax, 'YLim',[-100,10])
xlabel('频率/(Hz)')
ylabel('相位/(°)')
legend('普通二阶环','延迟3ms','延迟6ms','延迟10ms', 'Location','southwest')