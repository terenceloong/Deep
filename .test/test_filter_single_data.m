%% 测试单天线导航滤波器(使用数据)

%% 配置参数
psi0 = 35.3; %初始航向,deg
arm = [-0.1,0,0]*1; %杆臂,IMU指向天线
gyro0 = mean(imu(1:200,2:4));

para.dt = 0.01; %s,根据IMU采样周期设置
para.p0 = nCoV.storage.pos(1,1:3);
para.v0 = [0,0,0];
para.a0 = [psi0,0,0]; %deg
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
para.Q_dg = 0.01; %deg/s/s
para.Q_da = 0.1e-3; %g/s
para.sigma_gyro = 0.03; %deg/s
para.arm = arm; %m
para.gyro0 = gyro0; %deg/s
NF = filter_single(para);

% para.Q_gyro = 1.0; %deg/s
% para.Q_acc = 1e-2; %g
% NF = filter_single_11(para);

svN = nCoV.chN;
sv = zeros(svN,10);
n = size(nCoV.storage.ta,1);

%% 输出结果
output.satnav = zeros(n,14);
output.pos = zeros(n,3);
output.vel = zeros(n,3);
output.att = zeros(n,3);
output.clk = zeros(n,2);
output.bias = zeros(n,6);
output.P = zeros(n,20);
output.imu = zeros(n,6);
output.arm = zeros(n,3);

%% 计算
for k=1:n
    % 卫星量测
    for m=1:svN
        sv(m,:) = nCoV.storage.satmeas{m}(k,:);
    end
    indexP = (nCoV.storage.svsel(k,:)>=1)';
    indexV = (nCoV.storage.svsel(k,:)==2)';
    
    % 卫星导航解算
    satnav = satnavSolveWeighted(sv(indexV,:), NF.rp);
    
    % 导航滤波
    IMU = double(nCoV.storage.imu(k,:));
    NF.run(IMU, sv, indexP, indexV);
    
    % 杆臂修正
    Cnb = quat2dcm(NF.quat);
    Cen = dcmecef2ned(NF.pos(1), NF.pos(2));
    wb = IMU(1:3) - NF.bias(1:3); %角速度,rad/s
    r_arm = arm*Cnb*Cen;
    v_arm = cross(wb,arm)*Cnb*Cen;
    rp = NF.rp + r_arm;
    vp = NF.vp + v_arm;
    pos = ecef2lla(rp);
    vel = vp*Cen';
    
    % 存储结果
    output.satnav(k,:) = satnav;
    output.pos(k,:) = pos;
    output.vel(k,:) = vel;
    output.att(k,:) = NF.att;
    output.clk(k,:) = [NF.dtr, NF.dtv];
    output.bias(k,:) = NF.bias;
    P = NF.P;
    output.P(k,1:size(P,1)) = sqrt(diag(P));
    P_angle = var_phi2angle(P(1:3,1:3), Cnb);
    output.P(k,1:3) = sqrt(diag(P_angle));
    output.imu(k,:) = IMU;
    output.arm(k,:) = NF.arm;
end

%% 画位置输出
t = nCoV.storage.ta - nCoV.storage.ta(1);
t = t + nCoV.Tms/1000 - t(end);
figure('Name','位置')
for k=1:3
    subplot(3,1,k)
    plot(t,[output.satnav(:,k),output.pos(:,k)])
    grid on
end

%% 画速度输出
figure('Name','速度')
for k=1:3
    subplot(3,1,k)
    plot(t,[output.satnav(:,k+6),output.vel(:,k)])
    grid on
end

%% 画速度误差
figure('Name','速度误差')
for k=1:3
    subplot(3,1,k)
    plot(t,output.satnav(:,k+6)-output.vel(:,k))
    grid on
end

%% 画姿态输出
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

%% 画钟差钟频差
figure('Name','钟差钟频差')
subplot(2,1,1)
plot(t,[output.satnav(:,13),output.clk(:,1)])
grid on
subplot(2,1,2)
plot(t,[output.satnav(:,14),output.clk(:,2)])
grid on

%% 画陀螺仪零偏输出
r2d = 180/pi;
figure('Name','陀螺零偏(deg/s)')
for k=1:3
    subplot(3,1,k)
    plot(t,[output.imu(:,k),output.bias(:,k)]*r2d)
    grid on
    hold on
%     plot(t,gyroBias(k)+output.P(:,k+11)*r2d*3, 'LineStyle','--', 'Color','r')
%     plot(t,gyroBias(k)-output.P(:,k+11)*r2d*3, 'LineStyle','--', 'Color','r')
    set(gca, 'ylim', [-1,1])
end

%% 画加速度计零偏输出
figure('Name','加计零偏(m/s^2)')
for k=1:3
    subplot(3,1,k)
    plot(t,output.bias(:,k+3), 'LineWidth',0.5)
    grid on
end