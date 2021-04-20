% 画导航误差

% 检查是否是仿真数据
[~,name,~] = fileparts(data_file); %文件名拆分
prefix = strtok(name, '_');
if ~strcmp(prefix,'SIM') %不是仿真数据返回
    return
end

% 加载轨迹数据
trajnum = name(21:23); %轨迹编号
load(['~temp\traj\traj',trajnum])
dt_traj = trajGene_conf.dt; %轨迹采样间隔
dt_pos = nCoV.dtpos/1000; %接收机采样间隔
m = dt_pos / dt_traj; %跳点数

% 生成轨迹的时间序列
startTime_gps = UTC2GPS(tf, 8); %开始的GPS时间
tow = startTime_gps(2); %周内秒
n = size(traj,1);
time = tow + (0:n-1)'*dt_traj;

% 索引
n1 = find(time==nCoV.storage.ta(1),1);
n2 = find(time==nCoV.storage.ta(end),1);

t = nCoV.storage.ta - nCoV.storage.ta(end) + nCoV.Tms/1000;

%% 位置
pos_real = traj(n1:m:n2,7:9); %真实位置
pos_error = nCoV.storage.pos - pos_real; %位置误差

figure('Position',[488,200,560,520])

ax = subplot(3,1,1);
h = plot(t, pos_error(:,1), 'LineWidth',1);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('纬度误差/(°)')

ax = subplot(3,1,2);
h = plot(t, pos_error(:,2), 'LineWidth',1);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('经度误差/(°)')

ax = subplot(3,1,3);
h = plot(t, pos_error(:,3), 'LineWidth',1);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('高度误差/(m)')
xlabel('时间/(s)')

%% 速度
vel_real = traj(n1:m:n2,10:12); %真实速度
vel_error = nCoV.storage.vel - vel_real; %速度误差

figure('Position',[488,200,560,520])

ax = subplot(3,1,1);
h = plot(t, vel_error(:,1), 'LineWidth',1);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('北向速度误差/(m/s)')

ax = subplot(3,1,2);
h = plot(t, vel_error(:,2), 'LineWidth',1);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('东向速度误差/(m/s)')

ax = subplot(3,1,3);
h = plot(t, vel_error(:,3), 'LineWidth',1);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('地向速度误差/(m/s)')
xlabel('时间/(s)')

%% 姿态
att_real = traj(n1:m:n2,4:6); %真实姿态
att_error = nCoV.storage.att - att_real; %姿态误差
att_error(:,1) = attContinuous(att_error(:,1));

figure('Position',[488,200,560,520])

ax = subplot(3,1,1);
h = plot(t, att_error(:,1), 'LineWidth',1);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('航向角误差/(°)')

ax = subplot(3,1,2);
h = plot(t, att_error(:,2), 'LineWidth',1);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('俯仰角误差/(°)')

ax = subplot(3,1,3);
h = plot(t, att_error(:,3), 'LineWidth',1);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('滚转角误差/(°)')
xlabel('时间/(s)')