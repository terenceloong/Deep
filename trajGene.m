% 轨迹发生器

clearvars -except trajGene_conf trajGene_GUIflag
clc

%% 轨迹发生器配置预设值
% 使用GUI时外部会生成trajGene_conf,并将trajGene_GUIflag置1
if ~exist('trajGene_GUIflag','var') || trajGene_GUIflag~=1
    trajGene_conf.trajfile = 'traj004'; %轨迹文件
    trajGene_conf.p0 = [45.7364, 126.70775, 165]; %初始位置
%     trajGene_conf.p0 = [45, 126, 5000];
    trajGene_conf.Ts = 120; %轨迹时间
    trajGene_conf.dt = 0.005; %轨迹步长
end
if exist('trajGene_GUIflag','var')
    trajGene_GUIflag = 0; %立即将GUI标志清零
end

%% 参数
eval(trajGene_conf.trajfile) %运行轨迹文件
p0 = trajGene_conf.p0; %初始位置
Ts = trajGene_conf.Ts; %轨迹时间
dt = trajGene_conf.dt; %轨迹步长

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
acc      = zeros(N,3); %加速度
omega    = zeros(N,3); %角速度
accn     = zeros(N,3); %地理系加速度

%% 计算每个时刻的状态
index = ones(1,6); %时间区间索引
cmd = zeros(2,6); %第一行为值,第二行为导数
d2r = pi/180;
r2d = 180/pi;
w = 7.292115e-5; %地球自转角速度
p = p0; %每次计算的位置
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
    %----计算速度
	vh = cmd(1,1); %水平速度
    vy = cmd(1,2); %速度方向
    cos_vy = cosd(vy);
    sin_vy = sind(vy);
    v = [vh*cos_vy, vh*sin_vy, -cmd(1,3)]; %北东地速度
    %----计算曲率半径
    lat = p(1);
    lon = p(2);
    h = p(3);
    [Rm, Rn] = earthCurveRadius(lat);
    %----计算位置(第一次不用算)
    if k>1
        dp = (v0+v)/2*dt;
        lat = lat + dp(1)/(Rm+h)*r2d;
        lon = lon + dp(2)*secd(lat)/(Rn+h)*r2d;
        h = h - dp(3);
        p = [lat, lon, h];
    end
    %----计算角速度,加速度
    psi = cmd(1,4)*d2r;
    theta = cmd(1,5)*d2r;
    gamma = cmd(1,6)*d2r;
    Cnb = angle2dcm(psi, theta, gamma);
    Cbn = Cnb';
    vh_dot = cmd(2,1);
    vy_dot = cmd(2,2)*d2r;
    v_dot = [vh_dot*cos_vy-vh*sin_vy*vy_dot, ...
             vh_dot*sin_vy+vh*cos_vy*vy_dot, ...
             -cmd(2,3)]; %速度变化率
    a_dot = cmd(2,4:6)*d2r; %姿态角变化率
    g = gravitywgs84(h, lat); %重力加速度
    wnbb = a_dot * [-sin(theta), sin(gamma)*cos(theta), cos(gamma)*cos(theta);
                    0, cos(gamma), -sin(gamma); 1, 0, 0];
    wien = [w*cosd(lat), 0, -w*sind(lat)];
    wenn = [v(2)/(Rn+h), -v(1)/(Rm+h), -v(2)/(Rn+h)*tand(lat)];
    fn = v_dot - [0,0,g] + cross(2*wien+wenn,v);
    fb = fn*Cbn;
    wibb = (wien+wenn)*Cbn + wnbb;
    %----记录上次的速度
    v0 = v;
    %----存储
    vel_ned(k,:) = v;
    pos_lla(k,:) = p;
    pos_ecef(k,:) = lla2ecef(p);
    [r1,r2,r3] = dcm2angle(Cnb);
    angle(k,:) = [r1,r2,r3]*r2d;
    acc(k,:) = fb; %m/s^2
    omega(k,:) = wibb*r2d; %deg/s
    accn(k,:) = v_dot;
end

%% 保存轨迹
traj = [pos_ecef, angle, pos_lla, vel_ned, omega, acc, accn];
save(['~temp\traj\',trajGene_conf.trajfile,'.mat'], 'traj','trajTable','trajGene_conf');

%% 清除变量
clearvars -except traj trajTable trajGene_conf

%% 画图
trajGene_plot;