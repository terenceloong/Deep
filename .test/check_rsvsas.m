% 验证两种方法计算卫星加速度
% 第二种方法更快,因为少解了一次开普勒方程
% 运行前先载入一个预存星历

% 从预存星历中取一行星历,16参数
ephe = ephemeris.GPS_ephe(24,10:end);

n = 10*3600; %计算点数
t0 = 475200; %时间起点,看星历中的toe

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