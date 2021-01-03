% 轨迹发生器

clear
clc

%% 轨迹参数
traj1; %选择轨迹函数
p = [45.7364, 126.70775, 165]; %初始位置
Ts = 60; %轨迹时间
dt = 0.005; %轨迹步长

%% 检查轨迹是否正确
trajFun_check(VhFun, 'VhFun')
trajFun_check(VyFun, 'VyFun')
trajFun_check(VuFun, 'VuFun')
trajFun_check(AyFun, 'AyFun')
trajFun_check(ApFun, 'ApFun')
trajFun_check(ArFun, 'ArFun')

%% 生成轨迹表
trajTable = [trajFun_process(VhFun);
             trajFun_process(VyFun);
             trajFun_process(VuFun);
             trajFun_process(AyFun);
             trajFun_process(ApFun);
             trajFun_process(ArFun)];

%% 数据存储空间
N = Ts/dt + 1; %计算点数
vel_ned  = zeros(N,3); %地理系速度
pos_lla  = zeros(N,3); %纬经高
pos_ecef = zeros(N,3); %ecef位置
angle    = zeros(N,3); %姿态角
acc      = zeros(N-1,3); %加速度
omega    = zeros(N-1,3); %角速度

%% 计算每个时刻的状态
index = ones(1,6); %时间区间索引
cmd = zeros(2,6); %第一行为值,第二行为导数
for k=1:N
    t = (k-1)*dt; %当前时间
    %----更新索引,提取值
    for m=1:6
        if index(m)<trajTable{m,2} && trajTable{m,1}(index(m)+1)<t
            index(m) = index(m) + 1; %更新索引
        end
        valueFun = trajTable{m,3}{index(m)}; %值函数
        if isnumeric(valueFun)
            cmd(1,m) = valueFun;
        else
            cmd(1,m) = valueFun(t);
        end
        diffFun = trajTable{m,4}{index(m)}; %导数函数
        if isnumeric(diffFun)
            cmd(2,m) = diffFun;
        else
            cmd(2,m) = diffFun(t);
        end
    end
    %----计算
	vh = cmd(1,1); %水平速度
    vy = cmd(1,2); %速度方向
    v = [vh*cosd(vy), vh*sind(vy), -cmd(1,3)]; %北东地速度
    if k>1 %第一次是初值
        lat = p(1);
        h = p(3);
        [Rm, Rn] = earthCurveRadius(lat);
        dp = (v0+v)/2*dt;
        p(1) = p(1) + dp(1)/(Rm+h) /pi*180;
        p(2) = p(2) + dp(2)*secd(lat)/(Rn+h) /pi*180;
        p(3) = p(3) - dp(3);
    end
    v0 = v; %记录上次的速度
    %----存储
    vel_ned(k,:) = v;
    pos_lla(k,:) = p;
    pos_ecef(k,:) = lla2ecef(p);
    angle(k,:) = cmd(1,4:6);
    if k>1
%         acc(k-1,:) = fb;
%         omega(k-1,:) = wb;
    end
end

%% 保存轨迹
traj = [pos_ecef, pos_lla, vel_ned, angle, ...
        [[NaN,NaN,NaN];omega], [[NaN,NaN,NaN];acc]];
save('~temp\traj.mat', 'traj', 'dt');

%% 画图
t = (0:N-1)*dt;
figure %----位置
subplot(3,1,1)
plot(t, pos_lla(:,1), 'LineWidth',1)
grid on
subplot(3,1,2)
plot(t, pos_lla(:,2), 'LineWidth',1)
grid on
subplot(3,1,3)
plot(t, pos_lla(:,3), 'LineWidth',1)
grid on
figure %----速度
subplot(3,1,1)
plot(t, vel_ned(:,1), 'LineWidth',1)
grid on
subplot(3,1,2)
plot(t, vel_ned(:,2), 'LineWidth',1)
grid on
subplot(3,1,3)
plot(t, vel_ned(:,3), 'LineWidth',1)
grid on
figure %----姿态
subplot(3,1,1)
plot(t, angle(:,1), 'LineWidth',1)
grid on
subplot(3,1,2)
plot(t, angle(:,2), 'LineWidth',1)
grid on
subplot(3,1,3)
plot(t, angle(:,3), 'LineWidth',1)
grid on