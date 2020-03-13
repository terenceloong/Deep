%% 测试级联滤波器

clear
clc

%% 仿真时间
T = 100;
dt = 0.01;
n = T/dt;

%% 实际信号参数
a0 = 0.6; %加速度
f0 = 1;   %频率
p0 = 0;   %相位
v = 0.01; %相位测量噪声标准差

%% 本地信号参数
a = 0;  %加速度
f1 = 0; %一级滤波频率
f2 = 0; %二级滤波频率
p = 0;  %相位

%% 一级滤波器
Phi1 = [1,dt;0,1];
P1 = diag([1,1])^2;
Q1 = diag([0,1])^2 * dt^2; %调节w
R1 = v^2;
H1 = [1,0];

%% 二级滤波器
Phi2 = [1,dt;0,1];
P2 = diag([1,1])^2;
Q2 = diag([0,0.01])^2 * dt^2;
R2 = 0.02^2;
H2 = [1,0];

%% 计算
output = zeros(n,4);
X1 = [0;0];
for k=1:n
    %----实际信号生成
    p0 = p0 + f0*dt + 0.5*a0*dt^2; %相位更新
    f0 = f0 + a0*dt; %频率更新
    %----本地信号生成
    p = p + f1*dt; %相位更新
%     f1 = f1 + a*dt; %一级滤波频率更新,加了这句构成相互辅助,跟踪静差消除了
    f2 = f2 + a*dt; %二级滤波频率更新
    %----一级滤波
    Z = p - p0 + randn(1)*v; %相位差量测
    X1 = Phi1*X1;
    P1 = Phi1*P1*Phi1' + Q1;
    K = P1*H1' / (H1*P1*H1'+R1);
    X1 = X1 + K*(Z-H1*X1);
    P1 = (eye(2)-K*H1)*P1;
    P1 = (P1+P1')/2;
    p = p - X1(1); %相位修正
    f1 = f1 - X1(2); %频率修正
    X1 = [0;0];
    output(k,2) = f1 - f0; %一级滤波频率误差
    %----二级滤波
    Z = f2 - f1; %频率误差量测
    P2 = Phi2*P2*Phi2' + Q2;
    K = P2*H2' / (H2*P2*H2'+R2);
    X2 = K*Z;
    P2 = (eye(2)-K*H2)*P2;
    P2 = (P2+P2')/2;
    f2 = f2 - X2(1); %频率修正
    a = a - X2(2); %加速度修正
    %----二级滤波对一级滤波频率赋值,这不对滤波结果造成任何影响
    X1(2) = f2 - f1; %最关键的一句,不能直接赋值,要记录误差,取消这句,会出现振荡现象
    f1 = f2;
    %----存储
    output(k,1) = p - p0; %相位误差
    output(k,3) = f2 - f0; %二级滤波频率误差
    output(k,4) = a - a0; %加速度误差
end