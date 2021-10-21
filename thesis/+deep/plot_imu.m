% 画IMU输出的角速度和加速度曲线
t = nCoV.storage.ta - nCoV.storage.ta(end) + nCoV.Tms/1000;

%% 陀螺仪
figure('Position',[488,200,560,520])

ax = subplot(3,1,1);
h = plot(t, nCoV.storage.imu(:,1)/pi*180, 'LineWidth',1);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('x轴角速度/(°/s)')

ax = subplot(3,1,2);
h = plot(t, nCoV.storage.imu(:,2)/pi*180, 'LineWidth',1);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('y轴角速度/(°/s)')

ax = subplot(3,1,3);
h = plot(t, nCoV.storage.imu(:,3)/pi*180, 'LineWidth',1);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('z轴角速度/(°/s)')
xlabel('时间/(s)')

%% 加速度计
figure('Position',[488,200,560,520])

ax = subplot(3,1,1);
h = plot(t, nCoV.storage.imu(:,4), 'LineWidth',1);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('x轴加速度/(m/s^2)')

ax = subplot(3,1,2);
h = plot(t, nCoV.storage.imu(:,5), 'LineWidth',1);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('y轴加速度/(m/s^2)')

ax = subplot(3,1,3);
h = plot(t, nCoV.storage.imu(:,6), 'LineWidth',1);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('z轴加速度/(m/s^2)')
xlabel('时间/(s)')