% 画一些其他的曲线

%% 画载噪比
trec = time*[1;1e-3;1e-6] - t0; %接收时间序列

% 颜色表
newcolors = [   0, 0.447, 0.741;
            0.850, 0.325, 0.098;
            0.929, 0.694, 0.125;
            0.494, 0.184, 0.556;
            0.466, 0.674, 0.188;
            0.301, 0.745, 0.933;
            0.635, 0.078, 0.184;
                1, 0.075, 0.651;
                1,     0,     0;
                0,     0,     1];

figure('Name','载噪比')
colororder(newcolors) %设置颜色表
ax = axes;
ax.Box = 'on';
hold on
grid on

for k=1:32
    if any(~isnan(CN0(:,k)))
        plot(trec,CN0(:,k),  'LineWidth',1, 'DisplayName',['PRN ',num2str(k)])
    end
end

set(ax, 'FontSize',12)
set(ax, 'XLim',[trec(1),trec(end)])
set(ax, 'YLim',[10,55])
xlabel('时间/(s)')
ylabel('载噪比/(dB·Hz)')
legend('Location','southeast')

%% 画载波频率变化率(carrAccR)
% 理论上如果晶振的频率稳定,三阶PLL估计出的各通道的载波加速度是不相关的(仿真可以验证)
% 从实际接收机输出结果中发现,各通道的载波加速度有一定相关性,说明实际晶振的频率不稳定,相关性越强,晶振越差
trec = time*[1;1e-3;1e-6] - t0; %接收时间序列

% 颜色表
newcolors = [   0, 0.447, 0.741;
            0.850, 0.325, 0.098;
            0.929, 0.694, 0.125;
            0.494, 0.184, 0.556;
            0.466, 0.674, 0.188;
            0.301, 0.745, 0.933;
            0.635, 0.078, 0.184;
                1, 0.075, 0.651;
                1,     0,     0;
                0,     0,     1];

figure('Name','载波频率变化率(carrAccR)')
colororder(newcolors) %设置颜色表
ax = axes;
ax.Box = 'on';
hold on
grid on

for k=1:32
    if any(~isnan(carrAccR(:,k)))
        plot(trec,carrAccR(:,k),  'LineWidth',1, 'DisplayName',['PRN ',num2str(k)])
    end
end

set(ax, 'FontSize',12)
set(ax, 'XLim',[trec(1),trec(end)])
xlabel('时间/(s)')
ylabel('载波频率变化率/(Hz/s)')
legend('Location','southeast')

%% 画轨迹的速度和加速度刨面
tsim = motionSim(:,1) - t0;

figure
subplot(3,1,1)
plot(tsim,motionSim(:,5), 'LineWidth',1.5)
grid on
ax = gca;
set(ax, 'FontSize',12)
set(ax, 'XLim',[tsim(1),tsim(end)])
ylabel('\itv\rm_N/(m/s)')

subplot(3,1,2)
plot(tsim,motionSim(:,6), 'LineWidth',1.5)
grid on
ax = gca;
set(ax, 'FontSize',12)
set(ax, 'XLim',[tsim(1),tsim(end)])
ylabel('\itv\rm_E/(m/s)')

subplot(3,1,3)
plot(tsim,motionSim(:,7), 'LineWidth',1.5)
grid on
ax = gca;
set(ax, 'FontSize',12)
set(ax, 'XLim',[tsim(1),tsim(end)])
ylabel('\itv\rm_D/(m/s)')
xlabel('时间/(s)')

figure
subplot(3,1,1)
plot(tsim,motionSim(:,8), 'LineWidth',1.5)
grid on
ax = gca;
set(ax, 'FontSize',12)
set(ax, 'XLim',[tsim(1),tsim(end)])
ylabel('\ita\rm_N/(m/s^2)')

subplot(3,1,2)
plot(tsim,motionSim(:,9), 'LineWidth',1.5)
grid on
ax = gca;
set(ax, 'FontSize',12)
set(ax, 'XLim',[tsim(1),tsim(end)])
ylabel('\ita\rm_E/(m/s^2)')

subplot(3,1,3)
plot(tsim,motionSim(:,10), 'LineWidth',1.5)
grid on
ax = gca;
set(ax, 'FontSize',12)
set(ax, 'XLim',[tsim(1),tsim(end)])
ylabel('\ita\rm_D/(m/s^2)')
xlabel('时间/(s)')