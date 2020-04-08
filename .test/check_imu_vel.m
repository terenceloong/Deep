%% IMU测速测试
% 实际使用时将代码复制到新的脚本中修改参数,运行.
% 1.静止时以速度0和陀螺仪输出为量测;
% 2.航向角修正量约束为0;
% 3.运动检测(使用角速度).
% 参考check_imu_att.m

%%
clear
clc

%% 读IMU数据
imu = IMU_read(0);
imu(:,1) = []; %删除时间列

%% 参数
T = 100; %处理时间,s
T0 = 0; %开始时间,s
dt = 0.01; %采样周期,s
sigma_gyro = 0.15; %陀螺仪噪声标准差,deg/s
sigma_acc = 1.7; %加速度计噪声标准差,mg
sigma_v = 0.01; %设速度量测噪声用的,m/s
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
          [1,1,1]        *1, ...   % *m/s
          [1,1,1]/180*pi *0.2, ... % *deg/s
          [1,1,1]*0.01   *1 ...    % *mg
          ])^2;
Q1 = diag([[1,1,1]/180*pi *sigma_gyro, ... % *deg/s
           [1,1,1]*0.01   *sigma_acc, ...  % *mg
           [1,1,1]/180*pi *0.01, ...       % *deg/s/s
           [1,1,1]*0.01   *0.1 ...         % *mg/s:
           ])^2 * dt^2;
Q2 = diag([[1,1,1]/180*pi *sigma_gyro, ... % *deg/s
           [1,1,1]*0.01   *sigma_acc, ...  % *mg
           [1,1,1]/180*pi *0.01, ...       % *deg/s/s
           [1,1,1]*0.01   *0.1 ...         % *mg/s:
           ])^2 * dt^2;
H = zeros(6,12);
H(1:3,4:6) = eye(3); %速度量测
H(4:6,7:9) = eye(3); %角速度量测
R = diag([[1,1,1]*sigma_v, [1,1,1]/180*pi*sigma_gyro])^2;

%% 结果存储空间
output.nav   = zeros(n,9); %导航输出,姿态速度位置
output.bias  = zeros(n,6); %陀螺仪和加计零偏估计
output.P     = zeros(n,12); %P阵对角线元素开方
output.state = zeros(n,1); %运动状态
output.imu   = zeros(n,6); %IMU原始数据
output.wm    = zeros(n,1); %角速度的模长(补偿了初始零偏)
output.fm    = zeros(n,1); %加速度的模长

%% 初值
att = [0, pitch, roll] /180*pi; %rad
q = angle2quat(att(1), att(2), att(3));
v = [0, 0, 0];
p = [0, 0, 0];
% dgyro = [0,0,0]; %陀螺仪零偏补偿量,deg/s
dgyro = dgyro0; %已初始零偏为初值
dacc = [0,0,0]; %加速度计零偏补偿量,g
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
    fb = (imu(ki,4:6)-dacc) *g; %m/s^2
    %----姿态解算
    Omega = [  0,    wb(1),  wb(2),  wb(3);
            -wb(1),    0,   -wb(3),  wb(2);
            -wb(2),  wb(3),    0,   -wb(1);
            -wb(3), -wb(2),  wb(1),    0 ];
    q = q + 0.5*q*Omega*dt;
    Cnb = quat2dcm(q);
    Cbn = Cnb';
    %----速度解算
    fn = fb*Cnb;
    v = v + (fn+[0,0,g])*dt;
    %----位置解算
    p = p + v*dt;
    %----状态方程
    A = zeros(12);
    A(1:3,7:9) = -Cbn;
    A(4:6,1:3) = [0,-fn(3),fn(2); fn(3),0,-fn(1); -fn(2),fn(1),0];
    A(4:6,10:12) = Cbn;
    Phi = eye(12) + A*dt;
    %----量测更新
    if state==0 %静止状态
        %----一步预测方差阵
        P = Phi*P*Phi' + Q1;
        %----量测量
        Z = [v, wb]';
        %----滤波
        K = P*H' / (H*P*H'+R);
        X = K*Z;
        P = (eye(12)-K*H)*P;
        P = (P+P')/2;
        %----航向角修正量约束为0
        Y = zeros(1,12);
        Y(1) = Cnb(1,1)*Cnb(1,3);
        Y(2) = Cnb(1,2)*Cnb(1,3);
        Y(3) = -(Cnb(1,1)^2+Cnb(1,2)^2);
        X = X - P*Y'/(Y*P*Y')*Y*X;
    else %运动状态
        %----一步预测方差阵
        P = Phi*P*Phi' + Q2;
        X = zeros(12,1);
    end
    %----修正
    q = quatCorr(q, X(1:3)');
    v = v - X(4:6)';
    dgyro = dgyro + X(7:9)'/pi*180; %deg/s
	dacc = dacc + X(10:12)'/g; %g
    %----存储
    [r1,r2,r3] = quat2angle(q);
    output.nav(k,1:3) = [r1,r2,r3]/pi*180;
    output.nav(k,4:6) = v;
    output.nav(k,7:9) = p;
    output.bias(k,1:3) = dgyro;
    output.bias(k,4:6) = dacc;
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
    plot(t,output.nav(:,k), 'LineWidth',1)
    grid on
    hold on
    x = output.nav(:,k);
    x(output.state==0) = NaN;
    plot(t,x, 'LineWidth',1) %将运动部分标记为橘黄
end
% 画速度
figure('Name','速度')
for k=1:3
    subplot(3,1,k)
    plot(t,output.nav(:,k+3), 'LineWidth',1)
    grid on
    hold on
    x = output.nav(:,k+3);
    x(output.state==0) = NaN;
    plot(t,x, 'LineWidth',1) %将运动部分标记为橘黄
end
% 画位置
figure('Name','位置')
for k=1:3
    subplot(3,1,k)
    plot(t,output.nav(:,k+6), 'LineWidth',1)
    grid on
    hold on
    x = output.nav(:,k+6);
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
% 画加速度计零偏
figure('Name','加速度计零偏')
for k=1:3
    subplot(3,1,k)
    plot(t,output.bias(:,k+3), 'LineWidth',1)
    grid on
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