%% 测试双天线导航滤波器(使用轨迹,用历书算卫星)

%%
clear
clc

%% 随机数流
rands_gyro   = RandStream('mt19937ar', 'Seed',100, 'NormalTransform','Ziggurat');
rands_acc    = RandStream('mt19937ar', 'Seed',200, 'NormalTransform','Ziggurat');
rands_rho    = RandStream('mt19937ar', 'Seed',300, 'NormalTransform','Ziggurat');
rands_rhodot = RandStream('mt19937ar', 'Seed',400, 'NormalTransform','Ziggurat');
rands_phase  = RandStream('mt19937ar', 'Seed',500, 'NormalTransform','Ziggurat');

%% 配置参数
t0 = [2020,7,27,11,16,14]; %初始时间
trajName = 'traj000'; %轨迹文件名
dti = 0.01; %IMU采样周期,s
dtg = 0.01; %GPS采样周期,s
gyroBias = [0.1, 0.2, 0.3] *1; %陀螺仪零偏,deg/s
accBias = [-2, 2, -3]*0.01 *1; %加速度计零偏,m/s^2
gyroSigma = 0.05 *1; %陀螺仪噪声标准差,deg/s
accSigma = 0.006 *1; %加速度计噪声标准差,m/s^2
base = [1, 0, 0]; %基线矢量
sigma_rho = 4; %m
sigma_rhodot = 0.02; %m/s
sigma_phase = 0.005*0.19; %m
dtr0 = 1e-8; %初始钟差,s
dtv = 3e-9; %钟频差,s/s
c = 299792458;

%% 加载轨迹
load(['~temp\traj\',trajName,'.mat'])

%% 轨迹添加杆臂
arm0 = [0,0,0];
if any(arm0)
    traj = traj_addarm(traj, arm0);
end

%% 提取轨迹
Ts = trajGene_conf.Ts; %总时间
n = Ts / dti; %IMU数据数量
t = (1:n)'*dti; %IMU时间序列
m = dti / trajGene_conf.dt; %取数跳点数
nav0 = traj(1+(1:n)*m,[7:12,4:6]);

%% 加载历书,画星座图
t0g = UTC2GPS(t0, 8);
almanac_file = GPS.almanac.download('~temp\almanac', t0g); %下载历书
almanac = GPS.almanac.read(almanac_file); %读历书
svID = almanac(:,1);
almanac(:,1:4) = [];
% ax = GPS.constellation('~temp\almanac', t0, 8, traj(1,7:9));

%% IMU数据加噪声
imu = traj(1+(1:n)*m,13:18);
imu(:,1:3) = imu(:,1:3) + ones(n,1)*gyroBias + randn(rands_gyro,n,3)*gyroSigma;
imu(:,4:6) = imu(:,4:6) + ones(n,1)*accBias + randn(rands_acc,n,3)*accSigma;
imu(:,1:3) = imu(:,1:3)/180*pi; %rad/s

%% 滤波器参数
para.dt = dti; %s
para.p0 = traj(1,7:9);
para.v0 = traj(1,10:12);
para.a0 = traj(1,4:6) + [0.1,0,0]; %deg
para.P0_att = 1; %deg
para.P0_vel = 1; %m/s
para.P0_pos = 15; %m
para.P0_dtr = 5e-8; %s
para.P0_dtv = 3e-9; %s/s
para.P0_gyro = 0.2; %deg/s
para.P0_acc = 2e-3; %g
para.Q_gyro = gyroSigma; %deg/s
para.Q_acc = accSigma/9.8; %g
para.Q_dtv = 0.01e-9; %1/s
para.Q_dg = 0.01; %deg/s/s
para.Q_da = 0.1e-3; %g/s
para.sigma_gyro = gyroSigma; %deg/s
para.arm = arm0; %m
para.gyro0 = gyroBias; %deg/s
para.windupFlag = 0;
para.base = base;
NF = filter_double(para);

if norm(para.v0)>2
    NF.motion.state0 = 1;
    NF.motion.state = 1;
end

%% 输出结果
output.satnav = NaN(n,14);
output.pos = zeros(n,3);
output.vel = zeros(n,3);
output.att = zeros(n,3);
output.clk = zeros(n,2);
output.bias = zeros(n,6);
output.P = zeros(n,17);
output.imu = zeros(n,6);

%% 计算
d2r = pi/180;
M = dtg / dti; %控制GPS量测生成
m = 0;
for k=1:n
    %----IMU数据
    imu_k = imu(k,:);
    
    %----导航
    m = m+1;
    if m==M %有卫星量测
        m = 0;
        tk = k*dti;
        %----生成卫星量测---------------------------------------------------
        dtr = dtr0 + dtv*tk; %当前钟差
        tg = t0g + [0,tk]; %当前GPS时间
        pos0 = nav0(k,1:3); %当前位置
        vel0 = nav0(k,4:6); %当前速度
        att0 = nav0(k,7:9)*d2r; %当前姿态
        rsvs = rsvs_almanac(almanac, tg); %计算所有卫星位置速度
        [azi, ele] = aziele_xyz(rsvs(:,1:3), pos0); %计算所有卫星高度角方位角
        selIndex = find(ele>10); %所选卫星的行号
        selID = svID(selIndex); %所选卫星的ID号
        svN = length(selIndex); %卫星个数
        rs = rsvs(selIndex,1:3);
        vs = rsvs(selIndex,4:6);
        [rho, rhodot, rspu, Cen] = rho_rhodot_cal_geog(rs, vs, pos0, vel0); %计算相对距离和相对速度
        rho = rho + dtr*c + randn(rands_rho,svN,1)*sigma_rho;
        rhodot = rhodot./(1-sum(vs.*rspu,2)/c) + dtv*c + randn(rands_rhodot,svN,1)*sigma_rhodot;
        En = rspu*Cen';
        Cnb = angle2dcm(att0(1), att0(2), att0(3));
        rbn = base*Cnb;
        phase = En*rbn' + randn(rands_phase,svN,1)*sigma_phase;
        sv = [rs, vs, rho, rhodot, ones(svN,1)*sigma_rho^2, ones(svN,1)*sigma_rhodot^2, ...
              phase, ones(svN,1)*sigma_phase^2];
        %------------------------------------------------------------------
        output.satnav(k,:) = satnavSolve(sv, NF.rp); %卫星导航解算
%         output.satnav(k,:) = satnavSolveWeighted(sv, NF.rp);
        NF.run(imu_k, sv, true(svN,1), true(svN,1), true(svN,1));
    else %没有卫星量测
        NF.run(imu_k);
    end
    
    %----提取导航结果
    wb = imu_k(1:3) - NF.bias(1:3); %角速度,rad/s
    [pos, vel, att] = deal(NF.pos, NF.vel, NF.att);
    
    %----杆臂修正
    Cnb = angle2dcm(att(1)*d2r, att(2)*d2r, att(3)*d2r);
    r_arm = NF.arm*Cnb;
    v_arm = cross(wb,NF.arm)*Cnb;
    pos = pos + r_arm*NF.geogInfo.Cn2g;
    vel = vel + v_arm;
    
    %----存储结果
    output.pos(k,:) = pos;
    output.vel(k,:) = vel;
    output.att(k,:) = att;
    output.clk(k,:) = [NF.dtr, NF.dtv];
    output.bias(k,:) = NF.bias;
    P = NF.P;
    output.P(k,:) = sqrt(diag(P));
    P_angle = var_phi2angle(P(1:3,1:3), Cnb);
    output.P(k,1:3) = sqrt(diag(P_angle));
    output.imu(k,:) = imu_k;
end

%% 画图
t0 = t; %画图时间轴
plot_filter_double;