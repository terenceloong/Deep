% 画轨迹发生器产生的理论轨迹
% 执行trajGene.m后运行

%% 位置
t = (0:size(traj,1)-1)*trajGene_conf.dt;
figure('Position',[488,200,560,520])

ax = subplot(3,1,1);
h = plot(t, traj(:,7), 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('纬度/(°)')

ax = subplot(3,1,2);
h = plot(t, traj(:,8), 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('经度/(°)')

ax = subplot(3,1,3);
h = plot(t, traj(:,9), 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('高度/(m)')
xlabel('时间/(s)')

%% 速度
t = (0:size(traj,1)-1)*trajGene_conf.dt;
figure('Position',[488,200,560,520])

ax = subplot(3,1,1);
h = plot(t, traj(:,10), 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('北向速度/(m/s)')

ax = subplot(3,1,2);
h = plot(t, traj(:,11), 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('东向速度/(m/s)')

ax = subplot(3,1,3);
h = plot(t, traj(:,12), 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('地向速度/(m/s)')
xlabel('时间/(s)')

%% 姿态
t = (0:size(traj,1)-1)*trajGene_conf.dt;
figure('Position',[488,200,560,520])

ax = subplot(3,1,1);
h = plot(t, attContinuous(traj(:,4)), 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('航向角/(°)')

ax = subplot(3,1,2);
h = plot(t, traj(:,5), 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('俯仰角/(°)')

ax = subplot(3,1,3);
h = plot(t, traj(:,6), 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('滚转角/(°)')
xlabel('时间/(s)')

%% 角速度
t = (0:size(traj,1)-1)*trajGene_conf.dt;
figure('Position',[488,200,560,520])

ax = subplot(3,1,1);
h = plot(t, traj(:,13), 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('x轴角速度/(°/s)')

ax = subplot(3,1,2);
h = plot(t, traj(:,14), 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('y轴角速度/(°/s)')

ax = subplot(3,1,3);
h = plot(t, traj(:,15), 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('z轴角速度/(°/s)')
xlabel('时间/(s)')

%% 加速度
t = (0:size(traj,1)-1)*trajGene_conf.dt;
figure('Position',[488,200,560,520])

ax = subplot(3,1,1);
h = plot(t, traj(:,16), 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('x轴加速度/(m/s^2)')

ax = subplot(3,1,2);
h = plot(t, traj(:,17), 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('y轴加速度/(m/s^2)')

ax = subplot(3,1,3);
h = plot(t, traj(:,18), 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('z轴加速度/(m/s^2)')
xlabel('时间/(s)')