%% ���Թߵ��ӳٲ����ĵ����ߵ����˲���(ʹ�ù켣,������������)
% �ߵ���ǰ��,�ߵ�����������ʱ��ƥ��
% �����ַ�ʽ:һ�ǽ�IMU�������,��һ�����ڵ����˲����н������������

%%
clear
clc

%% �������
rands_gyro   = RandStream('mt19937ar', 'Seed',100, 'NormalTransform','Ziggurat');
rands_acc    = RandStream('mt19937ar', 'Seed',200, 'NormalTransform','Ziggurat');
rands_rho    = RandStream('mt19937ar', 'Seed',300, 'NormalTransform','Ziggurat');
rands_rhodot = RandStream('mt19937ar', 'Seed',400, 'NormalTransform','Ziggurat');

%% ���ò���
t0 = [2020,7,27,11,16,14]; %��ʼʱ��
trajName = 'traj103'; %�켣�ļ���
dti = 0.01; %IMU��������,s
dtg = 0.01; %GPS��������,s
gyroBias = [0.1, 0.2, 0.3] *1; %��������ƫ,deg/s
accBias = [-2, 2, -3]*0.01 *1; %���ٶȼ���ƫ,m/s^2
gyroSigma = 0.05 *1; %������������׼��,deg/s
accSigma = 0.006 *1; %���ٶȼ�������׼��,m/s^2
sigma_rho = 4; %m
sigma_rhodot = 0.02; %m/s
dtr0 = 1e-8; %��ʼ�Ӳ�,s
dtv = 3e-9; %��Ƶ��,s/s
delay = 0.005; %�ߵ��ӳ�,s
c = 299792458;

%% ���ع켣
load(['~temp\traj\',trajName,'.mat'])

%% �켣���Ӹ˱�
arm0 = [0,0,0];
if any(arm0)
    traj = traj_addarm(traj, arm0);
end

%% ʱ������
Ts = trajGene_conf.Ts; %��ʱ��
tj = (0:trajGene_conf.dt:trajGene_conf.Ts)'; %�켣ʱ������
n = Ts / dti; %IMU��������
t = (1:n)'*dti; %IMUʱ������
td = t + delay; %�ӳٺ��ʱ������

%% �켣��ֵ
nav0 = zeros(n,9); %������ֵ
nav0(:,1:3) = interp1(tj,traj(:,7:9), td, 'pchip'); %λ��
nav0(:,4:6) = interp1(tj,traj(:,10:12), td, 'pchip'); %�ٶ�
nav0(:,7) = interp1(tj,attContinuous(traj(:,4)), td, 'pchip'); %�����
nav0(:,8) = interp1(tj,traj(:,5), td, 'pchip'); %������
nav0(:,9) = interp1(tj,traj(:,6), td, 'pchip'); %��ת��

%% ��������,������ͼ
t0g = UTC2GPS(t0, 8);
almanac_file = GPS.almanac.download('~temp\almanac', t0g); %��������
almanac = GPS.almanac.read(almanac_file); %������
svID = almanac(:,1);
almanac(:,1:4) = [];
% ax = GPS.constellation('~temp\almanac', t0, 8, traj(1,7:9));

%% IMU���ݼ�����
m = dti / trajGene_conf.dt; %ȡ��������
imu = traj(1+(1:n)*m,13:18);
imu(:,1:3) = imu(:,1:3) + ones(n,1)*gyroBias + randn(rands_gyro,n,3)*gyroSigma;
imu(:,4:6) = imu(:,4:6) + ones(n,1)*accBias + randn(rands_acc,n,3)*accSigma;
imu(:,1:3) = imu(:,1:3)/180*pi; %rad/s

%% �˲�������
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
NF = filter_single(para);

if norm(para.v0)>2
    NF.motion.state0 = 1;
    NF.motion.state = 1;
end

%% ������
output.satnav = NaN(n,14);
output.pos = zeros(n,3);
output.vel = zeros(n,3);
output.att = zeros(n,3);
output.clk = zeros(n,2);
output.bias = zeros(n,6);
output.P = zeros(n,17);
output.imu = zeros(n,6);

%% ����
d2r = pi/180;
M = dtg / dti; %����GPS��������
m = 0;
imu0 = imu(1,:);
for k=1:n
    %----IMU����
    imu_k = imu(k,:);
    
    %----����
    m = m+1;
    if m==M %����������
        m = 0;
        tk = k*dti;
        %----������������---------------------------------------------------
        dtr = dtr0 + dtv*tk; %��ǰ�Ӳ�
        tg = t0g + [0,tk]; %��ǰGPSʱ��
        pos0 = nav0(k,1:3); %��ǰλ��
        vel0 = nav0(k,4:6); %��ǰ�ٶ�
        rsvs = rsvs_almanac(almanac, tg); %������������λ���ٶ�
        [azi, ele] = aziele_xyz(rsvs(:,1:3), pos0); %�����������Ǹ߶ȽǷ�λ��
        selIndex = find(ele>10); %��ѡ���ǵ��к�
        selID = svID(selIndex); %��ѡ���ǵ�ID��
        svN = length(selIndex); %���Ǹ���
        rs = rsvs(selIndex,1:3);
        vs = rsvs(selIndex,4:6);
        [rho, rhodot, rspu, ~] = rho_rhodot_cal_geog(rs, vs, pos0, vel0); %������Ծ��������ٶ�
        rho = rho + dtr*c + randn(rands_rho,svN,1)*sigma_rho;
        rhodot = rhodot./(1-sum(vs.*rspu,2)/c) + dtv*c + randn(rands_rhodot,svN,1)*sigma_rhodot;
        sv = [rs, vs, rho, rhodot, ones(svN,1)*sigma_rho^2, ones(svN,1)*sigma_rhodot^2];
        %------------------------------------------------------------------
        output.satnav(k,:) = satnavSolve(sv, NF.rp); %���ǵ�������
%         output.satnav(k,:) = satnavSolveWeighted(sv, NF.rp);
        imu_w = imu_k + (imu_k-imu0)*delay/dti*1; %IMU����
        NF.run(imu_w, sv, true(svN,1), true(svN,1));
        imu0 = imu_k;
    else %û����������
        NF.run(imu_k);
    end
    
    %----��ȡ�������
    wb = imu_k(1:3) - NF.bias(1:3); %���ٶ�,rad/s
    [pos, vel, att] = delayComp(NF.pos, NF.vel, NF.acc, NF.geogInfo.Cn2g, NF.delay, NF.quat, wb);
%     [pos, vel, att] = deal(NF.pos, NF.vel, NF.att);
    
    %----�˱�����
    Cnb = angle2dcm(att(1)*d2r, att(2)*d2r, att(3)*d2r);
    r_arm = NF.arm*Cnb;
    v_arm = cross(wb,NF.arm)*Cnb;
    pos = pos + r_arm*NF.geogInfo.Cn2g;
    vel = vel + v_arm;
    
    %----�洢���
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

%% ��ͼ
t0 = t; %��ͼʱ����
plot_filter_single;