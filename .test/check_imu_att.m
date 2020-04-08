%% IMU测姿测试
% 实际使用时将代码复制到新的脚本中修改参数,运行.
% 解决纯惯性姿态测量需要3个技巧:
% 1.加计陀螺输出作为量测量;
% 2.航向角修正量约束为0;
% 3.运动检测(使用角速度).
% 存在以下问题:
% 1.由于运动检测的滞后性,可能造成陀螺仪零偏被拉偏一些;
% 2.由于运动情况下陀螺零偏不稳定,造成运动结束后姿态偏移,偏移大小反应器件的动态性能;
% 3.重新进入静止状态时,由于要修正水平姿态,陀螺零偏的估计会有突变.为了防止这一突变,
% 可以在静止和运动状态下使用两组不同的Q,将运动时的姿态失准角Q设得较大.如果保持Q不变,
% 运动期间Q的增长赶不上姿态漂移的速度.

%%
clear
clc

%% 读IMU数据
imu = IMU_read(0);
imu(:,1) = []; %删除时间列

%% 统计所有角速度加速度矢量模长
% wm = vecnorm(imu(:,1:3)-mean(imu(1:100,1:3)),2,2);
% fm = vecnorm(imu(:,4:6),2,2);
% figure; plot(wm)
% figure; plot(fm)

%% 参数
T = 300; %处理时间,s
T0 = 0; %开始时间,s
dt = 0.01; %采样周期,s
sigma_gyro = 0.15; %陀螺仪噪声标准差,deg/s
sigma_acc = 1.7; %加速度计噪声标准差,mg
n = T/dt; %数据点数
k0 = T0/dt; %开始点的索引

%% 计算初始陀螺零偏
dgyro0 = mean(imu((1:100)+k0,1:3)); %deg/s,用100个点

%% 计算俯仰角滚转角
acc = mean(imu((1:100)+k0,4:6)); %用100个点
acc = acc / norm(acc);
pitch = asind(acc(1)); %deg
roll = atan2d(-acc(2),-acc(3)); %deg

%% 设置滤波器参数
P = diag([[1,1,1]/180*pi *1, ...   % *deg
          [1,1,1]/180*pi *0.2, ... % *deg/s
          ])^2;
Q1 = diag([[1,1,1]/180*pi *sigma_gyro, ... % *deg/s
           [1,1,1]/180*pi *0.01, ...       % *deg/s/s
           ])^2 * dt^2; %静止时使用的Q阵,姿态失准角对应的值按陀螺仪噪声设
Q2 = diag([[1,1,1]/180*pi *sigma_gyro*4, ... % *deg/s
           [1,1,1]/180*pi *0.01, ...       % *deg/s/s
           ])^2 * dt^2; %运动时使用的Q阵,姿态失准角对应的值往大了设,要保证P的增长跟实际姿态漂移匹配
H = zeros(6);
H(4:6,4:6) = eye(3);
R = diag([[1,1,1]*1e-3*sigma_acc, [1,1,1]/180*pi*sigma_gyro])^2;
% 加计量测的单位是g

%% 结果存储空间
output.att   = zeros(n,3); %姿态输出
output.bias  = zeros(n,3); %陀螺仪零偏估计
output.P     = zeros(n,6); %P阵对角线元素开方
output.state = zeros(n,1); %运动状态
output.imu   = zeros(n,6); %IMU原始数据
output.wm    = zeros(n,1); %角速度的模长(补偿了初始零偏)
output.fm    = zeros(n,1); %加速度的模长

%% 初值
att = [0, pitch, roll] /180*pi; %rad
q = angle2quat(att(1), att(2), att(3));
% dgyro = [0,0,0]; %陀螺仪零偏补偿量,deg/s
dgyro = dgyro0; %已初始零偏为初值
state = 0; %运动状态,0为静止,1为运动
cnt = 0; %计数器

%% 计算
g = 9.806;
for k=1:n
    ki = k+k0;
    %----判断运动状态
    wm = norm(imu(ki,1:3)-dgyro0); %角速度的模,deg/s
    fm = norm(imu(ki,4:6)); %加速度的模,g
    [state, cnt] = motion_state(state, cnt, wm);
    %----器件输出
    wb = (imu(ki,1:3)-dgyro) /180*pi; %rad/s
    fb = imu(ki,4:6) *g; %m/s^2
    %----姿态解算
    Omega = [  0,    wb(1),  wb(2),  wb(3);
            -wb(1),    0,   -wb(3),  wb(2);
            -wb(2),  wb(3),    0,   -wb(1);
            -wb(3), -wb(2),  wb(1),    0 ];
    q = q + 0.5*q*Omega*dt;
    Cnb = quat2dcm(q);
    Cbn = Cnb';
    %----状态方程
    A = zeros(6);
    A(1:3,4:6) = -Cbn;
    Phi = eye(6) + A*dt;
    %----量测更新
    if state==0 %静止状态
        %----一步预测方差阵
        P = Phi*P*Phi' + Q1;
        %----量测量
        fbg = fb / norm(fb); %归一化
        Z = [fbg+Cnb(:,3)', wb]';
        %----量测方程
        H(1,1) = -Cnb(1,2);
        H(1,2) =  Cnb(1,1);
        H(2,1) = -Cnb(2,2);
        H(2,2) =  Cnb(2,1);
        H(3,1) = -Cnb(3,2);
        H(3,2) =  Cnb(3,1);
        %----滤波
        K = P*H' / (H*P*H'+R);
        X = K*Z;
        P = (eye(6)-K*H)*P;
        P = (P+P')/2;
        %----航向角修正量约束为0
        Y = zeros(1,6);
        Y(1) = Cnb(1,1)*Cnb(1,3);
        Y(2) = Cnb(1,2)*Cnb(1,3);
        Y(3) = -(Cnb(1,1)^2+Cnb(1,2)^2);
        X = X - P*Y'/(Y*P*Y')*Y*X;
    else %运动状态
        %----一步预测方差阵
        P = Phi*P*Phi' + Q2;
        X = zeros(6,1);
    end
    %----修正
    q = quatCorr(q, X(1:3)');
    dgyro = dgyro + X(4:6)'/pi*180; %deg/s
    %----存储
    [r1,r2,r3] = quat2angle(q);
    output.att(k,:) = [r1,r2,r3]/pi*180;
    output.bias(k,:) = dgyro;
    output.P(k,:) = sqrt(diag(P));
    P_angle = var_phi2angle(P(1:3,1:3), Cnb);
    output.P(k,1:3) = sqrt(diag(P_angle));
    output.state(k) = state;
    output.imu(k,:) = imu(ki,:);
    output.wm(k) = wm;
    output.fm(k) = fm;
end

%% 画图
t = (1:n)'*dt;
% 画姿态角
figure('Name','姿态角')
for k=1:3
    subplot(3,1,k)
    plot(t,output.att(:,k), 'LineWidth',1)
    grid on
    hold on
    x = output.att(:,k);
    x(output.state==0) = NaN;
    plot(t,x, 'LineWidth',1) %将运动部分标记为橘黄
end
% 画陀螺仪零偏
figure('Name','陀螺仪零偏')
for k=1:3
    subplot(3,1,k)
    plot(t,output.imu(:,k))
    grid on
    hold on
    plot(t,output.bias(:,k), 'LineWidth',1)
    set(gca, 'ylim', [-1.5,1.5])
end
% 画运动状态
figure('Name','运动状态')
plot(t,output.wm)
hold on
grid on
plot(t,output.state, 'LineWidth',1)
set(gca, 'ylim', [-0.5,2])

%% 运动状态判断
function [state, cnt] = motion_state(state, cnt, wm)
    threshold = 0.8; %deg/s,角速度模长阈值
    if state==0
        if wm<threshold
            cnt = 0;
        else
            cnt = cnt + 1;
        end
        if cnt==3 %检测到连续3个点角速度大于阈值,认为是运动状态
            cnt = 0;
            state = 1;
        end
    else
        if wm>threshold
            cnt = 0;
        else
            cnt = cnt + 1;
        end
        if cnt==200 %检测到连续200个点角速度小于阈值,认为是静止状态
            cnt = 0;
            state = 0;
        end
    end
end