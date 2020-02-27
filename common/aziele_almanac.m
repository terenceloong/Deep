function result = aziele_almanac(almanac, t, p)
% 用历书计算卫星的方位角高度角,可以处理一个历书,也可以是一组
% almanac:8参数,[toe,sqa,e,M0,omega,Omega0,Omega_dot,i]
% t:周内秒数
% p:[lat,lon,h],deg,接收机位置
% result:[azi,ele],deg

if size(almanac,2)~=8
    error('Almanac error!')
end

% 地球参数(计算方位角高度角不用太精确,用啥都行)
%----GPS文档中给出的
% miu = 3.986005e14;
% w = 7.2921151467e-5;
%----WGS84文档和北斗文档给出的
miu = 3.986004418e14;
w = 7.292115e-5;

% 接收机位置
Cen = dcmecef2ned(p(1), p(2));
rp = lla2ecef(p)'; %接收机ecef坐标

% 观测历元与参考历元的时间差
toe = almanac(1,1);
dt = mod(t-toe+302400,604800)-302400; %限制在±302400

% 计算
N = size(almanac,1); %卫星个数
result = zeros(N,2);
for k=1:N
    %----计算卫星坐标
    a = almanac(k,2)^2;
    n = sqrt(miu/a^3);
    M = mod(almanac(k,4)+n*dt, 2*pi); %0-2*pi,平近点角
    e = almanac(k,3);
    E = kepler(M, e); %0-2*pi,偏近点角
    sin_v = sqrt(1-e^2)*sin(E) / (1-e*cos(E));
    cos_v = (cos(E)-e) / (1-e*cos(E));
    v = atan2(sin_v, cos_v); %真近点角
    phi = v+almanac(k,5);
    r = a*(1-e*cos(E));
    xp = r*cos(phi);
    yp = r*sin(phi);
    i = almanac(k,8);
    Omega = almanac(k,6) + (almanac(k,7)-w)*dt - w*toe;
    rs = [xp*cos(Omega) - yp*cos(i)*sin(Omega);
          xp*sin(Omega) + yp*cos(i)*cos(Omega);
          yp*sin(i)]; %卫星ecef坐标
    %----计算相对位置
    rps = rs-rp; %接收机指向卫星的位置矢量,ecef
    rpsu = rps/norm(rps); %单位矢量
    rpsu_n = Cen*rpsu; %转到地理系下
    %----计算方位角高度角
    result(k,1) = atan2d(rpsu_n(2),rpsu_n(1)); %方位角,deg
    result(k,2) = asind(-rpsu_n(3)); %高度角,deg
end

end