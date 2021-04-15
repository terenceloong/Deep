% 校验解算的速度和真实的速度

% 检查是否是仿真数据
[~,name,~] = fileparts(data_file); %文件名拆分
prefix = strtok(name, '_');
if ~strcmp(prefix,'SIM') %不是仿真数据返回
    return
end

% 加载轨迹数据
trajnum = name(end-1:end); %轨迹编号,两位
load(['~temp\traj\traj0',trajnum])
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

vel_real = traj(n1:m:n2,10:12); %真实速度
x1 = nCoV.storage.satnav(:,4)-vel_real(:,1); %纯卫星导航的误差
x2 = nCoV.storage.satnav(:,5)-vel_real(:,2);
x3 = nCoV.storage.satnav(:,6)-vel_real(:,3);
y1 = nCoV.storage.vel(:,1)-vel_real(:,1); %滤波后的误差
y2 = nCoV.storage.vel(:,2)-vel_real(:,2);
y3 = nCoV.storage.vel(:,3)-vel_real(:,3);

t = nCoV.storage.ta - nCoV.storage.ta(end) + nCoV.Tms/1000;

figure('Name','dVx')
plot(t,[x1,y1])
grid on
figure('Name','dVy')
plot(t,[x2,y2])
grid on
figure('Name','dVz')
plot(t,[x3,y3])
grid on