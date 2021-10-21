% 测试惯导解算
clear
clc
load('~temp\traj\traj010.mat')

T = 120;
dt = 0.01;
n = T/dt; %总计算点数
m = dt/trajGene_conf.dt; %跳点数
if T>trajGene_conf.Ts
    T = trajGene_conf.Ts;
end

nav = zeros(n,10); %导航结果
nav0 = zeros(n,10); %真值

para.p0 = traj(1,7:9);
para.v0 = traj(1,10:12);
para.a0 = traj(1,4:6);
para.dt = dt;
INS = ins_solve(para); %初始化

d2r = pi/180;
for k=1:n
    kj = m*k+1;
    imu = [traj(kj,13:15)*d2r, traj(kj,16:18)];
    INS.run(imu, 1);
%     INS.pos(3) = traj(kj,9); %长时间运行时高度需约束,否则导航会发散
    nav(k,1) = k*dt;
    nav(k,2:4) = INS.pos;
    nav(k,5:7) = INS.vel;
    nav(k,8:10) = INS.att;
    nav0(k,1) = k*dt;
    nav0(k,2:4) = traj(kj,7:9);
    nav0(k,5:7) = traj(kj,10:12);
    nav0(k,8:10) = traj(kj,4:6);
end

%% 画图
figure
subplot(3,3,1)
plot(nav(:,1), nav(:,2)-nav0(:,2));grid on;
subplot(3,3,4)
plot(nav(:,1), nav(:,3)-nav0(:,3));grid on;
subplot(3,3,7)
plot(nav(:,1), nav(:,4)-nav0(:,4));grid on;
subplot(3,3,2)
plot(nav(:,1), nav(:,5)-nav0(:,5));grid on;
subplot(3,3,5)
plot(nav(:,1), nav(:,6)-nav0(:,6));grid on;
subplot(3,3,8)
plot(nav(:,1), nav(:,7)-nav0(:,7));grid on;
subplot(3,3,3)
plot(nav(:,1), attContinuous(nav(:,8)-nav0(:,8)));grid on;
subplot(3,3,6)
plot(nav(:,1), nav(:,9)-nav0(:,9));grid on;
subplot(3,3,9)
plot(nav(:,1), nav(:,10)-nav0(:,10));grid on;