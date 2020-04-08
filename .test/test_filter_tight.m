%% 测试紧组合导航滤波器(静止情况)

%%
clear
clc

%% 仿真时间
T = 200;       %总时间
dt = 0.01;     %时间间隔
n = T / dt;    %仿真点数
t = (1:n)'*dt; %时间序列,列向量

%% 惯性器件指标
sigma_gyro = 0.15; %deg/s
sigma_acc = 1.5e-3; %g
bias_gyro = [0.2, 0, 0.6] *1; %deg/s
bias_acc = [0, 0, 2]*1e-3 *1; %g

%% 接收机指标
sigma_rho = 3; %m
sigma_rhodot = 0.1; %m/s
dtr = 1e-8; %初始钟差,s
dtv = 3e-9; %钟频差,s/s
c = 299792458;

%% 位置和姿态
p0 = [46, 126, 200];
rp = lla2ecef(p0);
a0 = [50, 0, 0]; %deg

%% 卫星位置
% 第一列为方位角,第二列为高度角,deg
sv_info = [  0, 45;
            23, 28;
            58, 80;
           100, 49;
           146, 34;
           186, 78;
           213, 43;
           255, 15;
           310, 20];
rho = 20000000; %卫星到接收机的距离,m

%% 仿真惯性器件输出
d2r = pi/180;
Cnb = angle2dcm(a0(1)*d2r, a0(2)*d2r, a0(3)*d2r);
acc = (Cnb*[0;0;-1])'; %真实加速度,g
imu = zeros(n,6);
imu(:,1:3) = ones(n,1)*bias_gyro + ...
             randn(n,3)*sigma_gyro;
imu(:,4:6) = ones(n,1)*acc + ...
             ones(n,1)*bias_acc + ...
             randn(n,3)*sigma_acc; 

%% 计算卫星位置速度
svN = size(sv_info,1); %卫星个数
sv_real = zeros(svN,8);
G = zeros(svN,4);
G(:,4) = -1;
Cen = dcmecef2ned(p0(1), p0(2));
for k=1:svN
    e = [-cosd(sv_info(k,2))*cosd(sv_info(k,1)), ...
         -cosd(sv_info(k,2))*sind(sv_info(k,1)), ...
          sind(sv_info(k,2))]; %卫星指向接收机的单位矢量
	rsp = e * rho; %卫星指向接收机的位置矢量
    sv_real(k,1:3) = rp - (rsp*Cen); %卫星位置
    sv_real(k,4:6) = 0; %卫星速度
    sv_real(k,7) = rho; %伪距
    sv_real(k,8) = 0; %伪距率
    G(k,1:3) = e;
end
D = inv(G'*G);
sqrt(diag(D)) %精度因子

%% 仿真结果存储空间
output.satnav = zeros(n,8); %卫星导航解算结果
output.filter = zeros(n,9); %滤波结果
output.bias = zeros(n,6); %零偏估计结果
output.dt = zeros(n,1); %钟差
output.df = zeros(n,1); %钟频差
output.P = zeros(n,17);

%% 初始化导航滤波器
para.dt = dt;
para.gyro0 = bias_gyro; %deg/s
para.p0 = p0;
para.v0 = [0,0,0];
para.a0 = a0 + [0,1,1]*0; %deg
para.P0_att = 1; %deg
para.P0_vel = 1; %m/s
para.P0_pos = 5; %m
para.P0_dtr = 2e-8; %s
para.P0_dtv = 3e-9; %s/s
para.P0_gyro = 0.2; %deg/s
para.P0_acc = 2e-3; %g
para.Q_gyro = sigma_gyro; %deg/s
para.Q_acc = sigma_acc; %g
para.Q_dtv = 0.01e-9; %1/s
para.Q_dg = 0.01; %deg/s/s
para.Q_da = 0.1e-3; %g/s
para.sigma_gyro = sigma_gyro; %deg/s
NF = filter_tight(para);

%% 开始仿真
sv_9_11 = [ones(svN,1)*2, ...
           ones(svN,1)*sigma_rho^2, ...
           ones(svN,1)*sigma_rhodot^2];
for k=1:n
    % 生成卫星量测
    dtr = dtr + dtv*dt; %当前钟差
    sv = sv_real;
    sv(:,7) = sv(:,7) + randn(svN,1)*sigma_rho + dtr*c;
    sv(:,8) = sv(:,8) + randn(svN,1)*sigma_rhodot + dtv*c;
    
    % 卫星导航解算
    satnav = satnavSolve(sv, rp);
    
    % 导航滤波
    NF.run(imu(k,:), [sv,sv_9_11]);
    dtv = dtv - NF.dtv;
    dtr = dtr - NF.dtr;
    
    % 存储结果
    output.satnav(k,:) = satnav([1,2,3,7,8,9,13,14]);
    output.filter(k,:) = [NF.pos, NF.vel, NF.att];
    output.bias(k,:) = NF.bias;
    output.dt(k) = dtr;
    output.df(k) = dtv;
    P = NF.P;
    output.P(k,:) = sqrt(diag(P));
    Cnb = quat2dcm(NF.quat);
    P_angle = var_phi2angle(P(1:3,1:3), Cnb);
    output.P(k,1:3) = sqrt(diag(P_angle));
end

%% 画位置输出
r2d = 180/pi;
figure('Name','位置')
for k=1:2
    subplot(3,1,k)
    plot(t, output.satnav(:,k))
    hold on
    grid on
    axis manual
    plot(t, output.filter(:,k), 'LineWidth',2)
    plot(t, p0(k)+output.P(:,k+6)*r2d*3, 'Color','y', 'LineStyle','--')
    plot(t, p0(k)-output.P(:,k+6)*r2d*3, 'Color','y', 'LineStyle','--')
    set(gca, 'xlim', [0,t(end)])
end
subplot(3,1,3)
plot(t, output.satnav(:,3))
hold on
grid on
axis manual
plot(t, output.filter(:,3), 'LineWidth',2)
plot(t, p0(3)+output.P(:,9)*3, 'Color','y', 'LineStyle','--')
plot(t, p0(3)-output.P(:,9)*3, 'Color','y', 'LineStyle','--')
set(gca, 'xlim', [0,t(end)])

%% 画速度输出
figure('Name','速度')
for k=1:3
    subplot(3,1,k)
    plot(t, output.satnav(:,k+3))
    hold on
    grid on
    axis manual
    plot(t, output.filter(:,k+3), 'LineWidth',2)
    plot(t,  output.P(:,k+3)*3, 'Color','y', 'LineStyle','--')
    plot(t, -output.P(:,k+3)*3, 'Color','y', 'LineStyle','--')
    set(gca, 'xlim', [0,t(end)])
end

%% 画姿态输出
r2d = 180/pi;
figure('Name','姿态')
for k=1:3
    subplot(3,1,k)
    plot(t, output.filter(:,k+6), 'LineWidth',2)
    hold on
    grid on
    axis manual
    plot(t, a0(k)+output.P(:,k)*r2d*3, 'Color','r', 'LineStyle','--')
    plot(t, a0(k)-output.P(:,k)*r2d*3, 'Color','r', 'LineStyle','--')
    set(gca, 'xlim', [0,t(end)])
end

%% 画陀螺仪零偏输出
r2d = 180/pi;
figure('Name','陀螺零偏')
for k=1:3
    subplot(3,1,k)
    plot(t, imu(:,k))
    hold on
    grid on
    axis manual
    plot(t, output.bias(:,k), 'LineWidth',2)
    plot(t, bias_gyro(k)+output.P(:,k+11)*r2d*3, 'Color','y', 'LineStyle','--')
    plot(t, bias_gyro(k)-output.P(:,k+11)*r2d*3, 'Color','y', 'LineStyle','--')
    set(gca, 'xlim', [0,t(end)])
end

%% 画加速度计零偏输出
figure('Name','加计零偏')
for k=1:3
    subplot(3,1,k)
    plot(t, output.bias(:,k+3), 'LineWidth',2)
    hold on
    grid on
    axis manual
    plot(t, bias_acc(k)+output.P(:,k+14)/9.8*3, 'Color','r', 'LineStyle','--')
    plot(t, bias_acc(k)-output.P(:,k+14)/9.8*3, 'Color','r', 'LineStyle','--')
    set(gca, 'xlim', [0,t(end)])
end