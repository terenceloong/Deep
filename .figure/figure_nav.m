% 画导航结果

%% 位置
t = nCoV.storage.ta - nCoV.storage.ta(end) + nCoV.Tms/1000;
figure('Position',[488,200,560,520])

ax = subplot(3,1,1);
h = plot(t, nCoV.storage.pos(:,1), 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('纬度/(°)')

ax = subplot(3,1,2);
h = plot(t, nCoV.storage.pos(:,2), 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('经度/(°)')

ax = subplot(3,1,3);
h = plot(t, nCoV.storage.pos(:,3), 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('高度/(m)')
xlabel('时间/(s)')

%% 速度
t = nCoV.storage.ta - nCoV.storage.ta(end) + nCoV.Tms/1000;
figure('Position',[488,200,560,520])

ax = subplot(3,1,1);
h = plot(t, nCoV.storage.vel(:,1), 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('北向速度/(m/s)')

ax = subplot(3,1,2);
h = plot(t, nCoV.storage.vel(:,2), 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('东向速度/(m/s)')

ax = subplot(3,1,3);
h = plot(t, nCoV.storage.vel(:,3), 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('地向速度/(m/s)')
xlabel('时间/(s)')

%% 姿态
t = nCoV.storage.ta - nCoV.storage.ta(end) + nCoV.Tms/1000;
figure('Position',[488,200,560,520])

ax = subplot(3,1,1);
h = plot(t, attContinuous(nCoV.storage.att(:,1)), 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('航向角/(°)')

ax = subplot(3,1,2);
h = plot(t, nCoV.storage.att(:,2), 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('俯仰角/(°)')

ax = subplot(3,1,3);
h = plot(t, nCoV.storage.att(:,3), 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('滚转角/(°)')
xlabel('时间/(s)')

%% 陀螺仪零偏估计值
t = nCoV.storage.ta - nCoV.storage.ta(end) + nCoV.Tms/1000;
figure('Position',[488,200,560,520])

ax = subplot(3,1,1);
h = plot(t, nCoV.storage.bias(:,1)/pi*180, 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('x轴陀螺零偏/(°/s)')

ax = subplot(3,1,2);
h = plot(t, nCoV.storage.bias(:,2)/pi*180, 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('y轴陀螺零偏/(°/s)')

ax = subplot(3,1,3);
h = plot(t, nCoV.storage.bias(:,3)/pi*180, 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('z轴陀螺零偏/(°/s)')
xlabel('时间/(s)')

%% 加速度计零偏估计值
t = nCoV.storage.ta - nCoV.storage.ta(end) + nCoV.Tms/1000;
figure('Position',[488,200,560,520])

ax = subplot(3,1,1);
h = plot(t, nCoV.storage.bias(:,4), 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('x轴加计零偏/(m/s^2)')

ax = subplot(3,1,2);
h = plot(t, nCoV.storage.bias(:,5), 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('y轴加计零偏/(m/s^2)')

ax = subplot(3,1,3);
h = plot(t, nCoV.storage.bias(:,6), 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('z轴加计零偏/(m/s^2)')
xlabel('时间/(s)')