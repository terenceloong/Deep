%% 测试双天线导航滤波器(接收机静止,卫星静止)

%%
clear
clc
% rng(1)

%% 配置参数
T = 100; %总时间
dti = 0.01; %IMU采样周期,s
dtg = 0.01; %GPS采样周期,s
gyroBias = [0.2, 0, 0.6] *1; %陀螺仪零偏,deg/s
accBias = [1, 0, 2]*0.01 *1; %加速度计零偏,m/s^2
gyroSigma = 0.15 *1; %陀螺仪噪声标准差,deg/s
accSigma = 0.015 *1; %加速度计噪声标准差,m/s^2
base = [1.3, 0, 0]; %基线矢量
sigma_rho = 3; %m
sigma_rhodot = 0.1; %m/s
sigma_phase = 0.8e-3; %m
dtr0 = 1e-8; %初始钟差,s
dtv = 3e-9; %钟频差,s/s
c = 299792458;

%% 接收机位置和姿态
p0 = [46, 126, 200];
rp = lla2ecef(p0);
a0 = [50, 0, 0]; %deg
n = T / dti;
traj = zeros(n,12);
traj(:,7:9) = ones(n,1)*p0;
traj(:,4:6) = ones(n,1)*a0;

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
acc = (Cnb*[0;0;-gravitywgs84(p0(3),p0(1))])'; %真实加速度,m/s^2
imu = zeros(n,6);
imu(:,1:3) = ones(n,1)*gyroBias*d2r + ...
             randn(n,3)*gyroSigma*d2r; %rad/s
imu(:,4:6) = ones(n,1)*acc + ...
             ones(n,1)*accBias + ...
             randn(n,3)*accSigma; %m/s^2

%% 计算卫星位置速度
svN = size(sv_info,1); %卫星个数
sv_real = zeros(svN,8);
phase = zeros(svN,1);
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
    phase(k) = base*Cnb*e';
end
E = G(:,1:3);
D = inv(G'*G);
sqrt(diag(D)) %精度因子

%% 滤波器参数
para.dt = dti; %s
para.p0 = p0;
para.v0 = [0,0,0];
para.a0 = a0; %deg
para.P0_att = 1; %deg
para.P0_vel = 1; %m/s
para.P0_pos = 5; %m
para.P0_dtr = 2e-8; %s
para.P0_dtv = 3e-9; %s/s
para.P0_gyro = 0.2; %deg/s
para.P0_acc = 2e-3; %g
para.Q_gyro = gyroSigma; %deg/s
para.Q_acc = accSigma/9.8; %g
para.Q_dtv = 0.03e-9; %1/s
para.Q_dg = 0.01; %deg/s/s
para.Q_da = 0.1e-3; %g/s
para.sigma_gyro = gyroSigma; %deg/s
para.arm = [0,0,0]; %m
para.gyro0 = gyroBias; %deg/s
para.windupFlag = 0;
para.base = base;
NF = filter_double(para);

%% 输出结果
output.satnav = NaN(n,14);
output.satatt = NaN(n,6);
output.pos = zeros(n,3);
output.vel = zeros(n,3);
output.att = zeros(n,3);
output.clk = zeros(n,2);
output.bias = zeros(n,6);
output.P = zeros(n,17);
output.imu = zeros(n,6);

%% 计算
M = dtg / dti; %控制GPS量测生成
m = 0;
for k=1:n
    %----IMU数据
    imu_k = imu(k,:);
    
    %----导航
    m = m+1;
    if m==M %有卫星量测
        m = 0;
        %----生成卫星量测---------------------------------------------------
        dtr = dtr0 + dtv*k*dti; %当前钟差
        sv = [sv_real, ones(svN,1)*sigma_rho^2, ones(svN,1)*sigma_rhodot^2, ...
              phase, ones(svN,1)*sigma_phase^2];
        sv(:,7) = sv(:,7) + dtr*c + randn(svN,1)*sigma_rho;
        sv(:,8) = sv(:,8) + dtv*c + randn(svN,1)*sigma_rhodot;
        sv(:,11) = sv(:,11) + randn(svN,1)*sigma_phase;
        %------------------------------------------------------------------
        output.satnav(k,:) = satnavSolve(sv, NF.rp); %卫星导航解算
%         x = (E'*E)\(E'*sv(:,11));
%         output.satatt(k,1) = atan2d(x(2),x(1));
%         output.satatt(k,2) = -asind(x(3)/norm(x));
%         output.satatt(k,3:5) = x';
        x = (G'*G)\(G'*sv(:,11));
        output.satatt(k,1) = atan2d(x(2),x(1));
        output.satatt(k,2) = -asind(x(3)/norm(x(1:3)));
        output.satatt(k,3:6) = x';
        %------------------------------------------------------------------
        NF.run(imu_k, sv, true(svN,1), true(svN,1), true(svN,1));
    else %没有卫星量测
        NF.run(imu_k);
    end
    
    %----存储结果
    output.pos(k,:) = NF.pos;
    output.vel(k,:) = NF.vel;
    output.att(k,:) = NF.att;
    output.clk(k,:) = [NF.dtr, NF.dtv];
    output.bias(k,:) = NF.bias;
    P = NF.P;
    output.P(k,:) = sqrt(diag(P));
    Cnb = quat2dcm(NF.quat);
    P_angle = var_phi2angle(P(1:3,1:3), Cnb);
    output.P(k,1:3) = sqrt(diag(P_angle));
    output.imu(k,:) = imu_k;
end

%% 画图
plot_filter_double;