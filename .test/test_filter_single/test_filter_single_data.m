%% 测试单天线导航滤波器(使用软件接收机输出的数据)

%% 滤波器参数
arm = [0.32,0,0]*0; %杆臂,IMU指向天线 [0.32,0.005,-0.003]
gyro0 = mean(imu(1:200,2:4));

para.dt = 0.01; %s,根据IMU采样周期设置
para.p0 = nCoV.storage.pos(1,1:3);
para.v0 = double(nCoV.storage.vel(1,1:3));
para.a0 = double(nCoV.storage.att(1,1:3));
para.P0_att = 1; %deg
para.P0_vel = 1; %m/s
para.P0_pos = 15; %m
para.P0_dtr = 5e-8; %s
para.P0_dtv = 3e-9; %s/s
para.P0_gyro = 0.2; %deg/s
para.P0_acc = 2e-3; %g
para.Q_gyro = 0.2; %deg/s
para.Q_acc = 2e-3; %g
para.Q_dtv = 0.01e-9; %1/s
para.Q_dg = 0.01*0.1; %deg/s/s
para.Q_da = 0.1e-3; %g/s
para.sigma_gyro = 0.07; %deg/s
para.arm = arm; %m
para.gyro0 = gyro0; %deg/s
[~,name,~] = fileparts(data_file);
if strcmp(name(1:3),'SIM')
    para.windupFlag = 0;
else
    para.windupFlag = 1;
end
NF = filter_single(para);

if norm(para.v0)>2
    NF.motion.state0 = 1;
    NF.motion.state = 1;
end

%% 卫星信息
svN = nCoV.chN;
sv = zeros(svN,10);
n = size(nCoV.storage.ta,1);

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
for k=1:n
    %----卫星量测
    for m=1:svN
        sv(m,:) = nCoV.storage.satmeas{m}(k,1:10);
    end
    indexP = (nCoV.storage.svsel(k,:)>=1)';
    indexV = (nCoV.storage.svsel(k,:)==2)';
    
    %----卫星导航解算
    output.satnav(k,:) = satnavSolveWeighted(sv(indexV,:), NF.rp);
    
    %----IMU数据
    imu_k = double(nCoV.storage.imu(k,:));
    
    %----导航滤波
    NF.run(imu_k, sv, indexP, indexV);
    
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
t = nCoV.storage.ta - nCoV.storage.ta(1);
t = t + nCoV.Tms/1000 - t(end);
r2d = 180/pi;

figure('Name','位置')
for k=1:3
    subplot(3,1,k)
    plot(t,[output.satnav(:,k),output.pos(:,k)])
    grid on
end

figure('Name','速度')
for k=1:3
    subplot(3,1,k)
    plot(t,[output.satnav(:,k+6),output.vel(:,k)])
    grid on
end

figure('Name','速度误差')
for k=1:3
    subplot(3,1,k)
    plot(t,output.satnav(:,k+6)-output.vel(:,k))
    grid on
end

figure('Name','姿态')
subplot(3,1,1)
plot(t,attContinuous(output.att(:,1)), 'LineWidth',0.5)
grid on
subplot(3,1,2)
plot(t,output.att(:,2), 'LineWidth',0.5)
grid on
subplot(3,1,3)
plot(t,output.att(:,3), 'LineWidth',0.5)
grid on

figure('Name','钟差钟频差')
subplot(2,1,1)
plot(t,[output.satnav(:,13),output.clk(:,1)])
grid on
subplot(2,1,2)
plot(t,[output.satnav(:,14),output.clk(:,2)])
grid on

figure('Name','陀螺零偏(deg/s)')
for k=1:3
    subplot(3,1,k)
    plot(t,[output.imu(:,k),output.bias(:,k)]*r2d)
    grid on
    set(gca, 'ylim', [-1,1])
end

figure('Name','加计零偏(m/s^2)')
for k=1:3
    subplot(3,1,k)
    plot(t,output.bias(:,k+3), 'LineWidth',1)
    grid on
end