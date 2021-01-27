% 轨迹发生器输出画图
% 轨迹变量名为traj

t = (0:size(traj,1)-1)*trajGene_conf.dt; %时间序列

%----位置
figure
subplot(3,1,1)
plot(t, traj(:,7), 'LineWidth',1)
grid on
set(gca, 'xlim', [t(1),t(end)])
title('位置')
subplot(3,1,2)
plot(t, traj(:,8), 'LineWidth',1)
grid on
set(gca, 'xlim', [t(1),t(end)])
subplot(3,1,3)
plot(t, traj(:,9), 'LineWidth',1)
grid on
set(gca, 'xlim', [t(1),t(end)])

%----速度
figure
subplot(3,1,1)
plot(t, traj(:,10), 'LineWidth',1)
grid on
set(gca, 'xlim', [t(1),t(end)])
title('速度')
subplot(3,1,2)
plot(t, traj(:,11), 'LineWidth',1)
grid on
set(gca, 'xlim', [t(1),t(end)])
subplot(3,1,3)
plot(t, traj(:,12), 'LineWidth',1)
grid on
set(gca, 'xlim', [t(1),t(end)])

%----姿态
figure
subplot(3,1,1)
plot(t, traj(:,4), 'LineWidth',1)
grid on
set(gca, 'xlim', [t(1),t(end)])
title('姿态')
subplot(3,1,2)
plot(t, traj(:,5), 'LineWidth',1)
grid on
set(gca, 'xlim', [t(1),t(end)])
subplot(3,1,3)
plot(t, traj(:,6), 'LineWidth',1)
grid on
set(gca, 'xlim', [t(1),t(end)])

%----角速度&加速度
figure
subplot(3,2,1)
plot(t, traj(:,13), 'LineWidth',1)
grid on
set(gca, 'xlim', [t(1),t(end)])
subplot(3,2,3)
plot(t, traj(:,14), 'LineWidth',1)
grid on
set(gca, 'xlim', [t(1),t(end)])
subplot(3,2,5)
plot(t, traj(:,15), 'LineWidth',1)
grid on
set(gca, 'xlim', [t(1),t(end)])
subplot(3,2,2)
plot(t, traj(:,16), 'LineWidth',1)
grid on
set(gca, 'xlim', [t(1),t(end)])
subplot(3,2,4)
plot(t, traj(:,17), 'LineWidth',1)
grid on
set(gca, 'xlim', [t(1),t(end)])
subplot(3,2,6)
plot(t, traj(:,18), 'LineWidth',1)
grid on
set(gca, 'xlim', [t(1),t(end)])

clearvars t