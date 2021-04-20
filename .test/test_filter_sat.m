%% 测试卫星导航滤波器(静止情况)

%%
clear
clc

%% 仿真时间
T = 500;       %总时间
dt = 1;        %时间间隔
n = T / dt;    %仿真点数
t = (1:n)'*dt; %时间序列,列向量

%% 接收机指标
sigma_rho = 3; %m
sigma_rhodot = 0.04; %m/s
dtr = 1e-8; %初始钟差,s
dtv = 3e-9; %钟频差,s/s
c = 299792458;

%% 位置
p0 = [46, 126, 200];
rp = lla2ecef(p0);

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

%% 计算卫星位置速度
svN = size(sv_info,1); %卫星个数
sv_real = zeros(svN,8);
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
end
D = inv(G'*G);
sqrt(diag(D)) %精度因子

%% 仿真结果存储空间
output.satnav = zeros(n,8); %卫星导航解算结果
output.filter = zeros(n,11); %滤波结果
output.dt = zeros(n,1); %钟差
output.df = zeros(n,1); %钟频差
output.P = zeros(n,11);

%% 初始化导航滤波器
para.dt = dt;
para.p0 = p0;
para.v0 = [0,0,0];
para.P0_pos = 5; %m
para.P0_vel = 1; %m/s
para.P0_acc = 1; %m/s^2
para.P0_dtr = 2e-8; %s
para.P0_dtv = 3e-9; %s/s
para.Q_pos = 0;
para.Q_vel = 0;
para.Q_acc = 1e-4; %时间间隔大时,这个数不能大
para.Q_dtr = 0;
para.Q_dtv = 1e-9;
NF = filter_sat(para);

%% 开始仿真
for k=1:n
    % 生成卫星量测
    dtr = dtr + dtv*dt; %当前钟差
    sv = sv_real;
    sv(:,7) = sv(:,7) + randn(svN,1)*sigma_rho + dtr*c;
    sv(:,8) = sv(:,8) + randn(svN,1)*sigma_rhodot + dtv*c;
    sv(:,9) = sigma_rho^2;
    sv(:,10) = sigma_rhodot^2;
    
    % 卫星导航解算
    satnav = satnavSolve(sv, rp);
    
    % 导航滤波
    NF.run(sv, true(svN,1), true(svN,1));
    
    % 存储结果
    output.satnav(k,:) = satnav([1,2,3,7,8,9,13,14]);
    output.filter(k,:) = [NF.pos, NF.vel, NF.acc, NF.dtr, NF.dtv];
    output.dt(k) = dtr;
    output.df(k) = dtv;
    output.P(k,:) = sqrt(diag(NF.P));
end

%% 画位置输出
r2d = 180/pi;
figure('Name','位置')

subplot(3,1,1)
plot(t, output.satnav(:,1))
hold on
grid on
axis manual
plot(t, output.filter(:,1), 'LineWidth',1)
plot(t, p0(1)+output.P(:,1)*NF.geogInfo.dlatdn*r2d*3, 'Color','k', 'LineStyle','--')
plot(t, p0(1)-output.P(:,1)*NF.geogInfo.dlatdn*r2d*3, 'Color','k', 'LineStyle','--')
set(gca, 'xlim', [0,t(end)])

subplot(3,1,2)
plot(t, output.satnav(:,2))
hold on
grid on
axis manual
plot(t, output.filter(:,2), 'LineWidth',1)
plot(t, p0(2)+output.P(:,2)*NF.geogInfo.dlonde*r2d*3, 'Color','k', 'LineStyle','--')
plot(t, p0(2)-output.P(:,2)*NF.geogInfo.dlonde*r2d*3, 'Color','k', 'LineStyle','--')
set(gca, 'xlim', [0,t(end)])

subplot(3,1,3)
plot(t, output.satnav(:,3))
hold on
grid on
axis manual
plot(t, output.filter(:,3), 'LineWidth',1)
plot(t, p0(3)+output.P(:,3)*3, 'Color','k', 'LineStyle','--')
plot(t, p0(3)-output.P(:,3)*3, 'Color','k', 'LineStyle','--')
set(gca, 'xlim', [0,t(end)])

%% 画速度输出
figure('Name','速度')
for k=1:3
    subplot(3,1,k)
    plot(t, output.satnav(:,k+3))
    hold on
    grid on
    axis manual
    plot(t, output.filter(:,k+3), 'LineWidth',1)
    plot(t,  output.P(:,k+3)*3, 'Color','k', 'LineStyle','--')
    plot(t, -output.P(:,k+3)*3, 'Color','k', 'LineStyle','--')
    set(gca, 'xlim', [0,t(end)])
end

%% 画加速度
figure('Name','加速度')
for k=1:3
    subplot(3,1,k)
    plot(t, output.filter(:,k+6), 'LineWidth',1)
    hold on
    grid on
    axis manual
    plot(t,  output.P(:,k+6)*3, 'Color','r', 'LineStyle','--')
    plot(t, -output.P(:,k+6)*3, 'Color','r', 'LineStyle','--')
    set(gca, 'xlim', [0,t(end)])
end

%% 画钟差
figure('Name','钟差')
subplot(2,1,1)
plot(t, output.dt-output.filter(:,10), 'LineWidth',1)
grid on
set(gca, 'xlim', [0,t(end)])

subplot(2,1,2)
plot(t, output.satnav(:,8))
hold on
grid on
plot(t, output.filter(:,11))
set(gca, 'xlim', [0,t(end)])