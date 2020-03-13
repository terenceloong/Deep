%% 验证alpha-beta滤波系数
% 二阶卡尔曼滤波收敛后为alpha-beta滤波,形式上是PI控制器.
% 有两个系数,可以通过求解黎卡提方程获得,也可以用解析法获得,二者结果一样
% alpha为相位修正系数,beta为频率修正系数
% 可调整的参数为:dt,w,v

clear
clc

%% 参数
dt = 0.01; %离散时间
Phi = [1,dt;0,1];
H = [1,0];
w = 0.1; %过程噪声标准差
Q = diag([0,w])^2 * dt^2;
v = 0.1; %量测噪声标准差
R = v^2;

%% 黎卡提方程求解计算alpha,beta
[P,~,~] = idare(Phi',H',Q,R,[],[]); %P是一步预测方差收敛值
EA = Phi*P*Phi'- P - (Phi*P*H')/(H*P*H'+R)*(H*P*Phi') + Q; %误差阵为0说明求解正确
K = P*H'/(H*P*H'+R); %卡尔曼增益
alpha = K(1);
beta = K(2);
disp([alpha,beta])

%% 解析计算alpha,beta
% https://en.wikipedia.org/wiki/Alpha_beta_filter
lamda = w/v*dt^2;
r = (4 + lamda - sqrt(8*lamda+lamda^2)) / 4;
alpha = 1-r^2;
beta = (2*(2-alpha) - 4*sqrt(1-alpha)) / dt;
disp([alpha,beta])