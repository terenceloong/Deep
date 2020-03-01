function rs = rs_almanac(almanac, t)
% 使用历书计算卫星ecef位置(多颗卫星)
% almanac:8参数历书,每行为1颗卫星
% [toe,sqa,e,M0,omega,Omega0,Omega_dot,i]
% t:周内秒数
% rs:卫星ecef位置,每行为1颗卫星

% 检查历书参数个数
[svN, paraN] = size(almanac); %卫星个数和参数个数
if paraN~=8
    error('Almanac error!')
end

% 地球参数(不用太精确,用哪个都行)
%----GPS文档中给出的
% miu = 3.986005e14;
% w = 7.2921151467e-5;
%----WGS84文档和北斗文档给出的
miu = 3.986004418e14;
w = 7.292115e-5;

% 观测历元与参考历元的时间差
toe = almanac(1,1);
dt = mod(t-toe+302400,604800)-302400; %限制在±302400

% 计算所有卫星ecef位置
rs = zeros(svN,3);
for k=1:svN
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
    rs(k,1) = xp*cos(Omega) - yp*cos(i)*sin(Omega);
    rs(k,2) = xp*sin(Omega) + yp*cos(i)*cos(Omega);
    rs(k,3) = yp*sin(i);
end

end