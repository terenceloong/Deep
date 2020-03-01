%% 验证两种方法计算卫星加速度
% 第二种方法更快,因为少解了一次开普勒方程.
% 运行结束后查看sv1,sv2,dsv变量.
% dsv中位置速度误差应该为0,加速度误差10^-6以下.
% 运行前先载入一个预存星历.

%% 取星历
ephe = ephemeris.GPS_ephe(24,10:end); %从预存星历中取一行星历(16参数)
t0 = ephe(1); %时间起点,星历中的toe
n = 10*3600; %计算点数,10个小时,1s一个点

%% 方法1
sv1 = zeros(n,9); %[x,y,x,vx,vy,vz,ax,ay,az]
T = 0.1; %差分时间间隔,s
t = t0;
for k=1:n
    [rsvs1, ~] = LNAV.rsvs_ephe(ephe, t);
    [rsvs2, ~] = LNAV.rsvs_ephe(ephe, t+T);
    sv1(k,1:6) = rsvs1;
    sv1(k,7:9) = (rsvs2(4:6)-rsvs1(4:6)) / T; %速度做差分求加速度
    t = t+1; %前进1s
end

%% 方法2
sv2 = zeros(n,9); %[x,y,x,vx,vy,vz,ax,ay,az]
t = t0;
for k=1:n
    [sv2(k,:), ~] = LNAV.rsvsas_ephe(ephe, t);
    t = t+1; %前进1s
end

%% 比较差异
dsv = sv1-sv2;