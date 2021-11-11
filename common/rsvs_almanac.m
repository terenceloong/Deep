function rsvs = rsvs_almanac(almanac, t)
% 使用历书计算卫星ecef位置和速度(多颗卫星)
% almanac:9参数历书,每行为1颗卫星
% [week,toe,sqa,e,M0,omega,Omega0,Omega_dot,i]
% t:[week,second]
% rsvs:[x,y,z,vx,vy,vz],每行为1颗卫星

% 检查历书参数个数
[svN, paraN] = size(almanac); %卫星个数和参数个数
if paraN~=9
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
toe = almanac(1,2);
dt = rem(t(1)-almanac(1,1),1024)*604800 + (t(2)-toe);

% 计算所有卫星ecef位置和速度
rsvs = zeros(svN,6);
for k=1:svN
    a = almanac(k,3)^2;
    n = sqrt(miu/a^3);
    M = mod(almanac(k,5)+n*dt, 2*pi); %0-2*pi,平近点角
    e = almanac(k,4);
    E = kepler(M, e); %0-2*pi,偏近点角
    sin_E = sin(E);
    cos_E = cos(E);
    sin_v = sqrt(1-e^2)*sin_E / (1-e*cos_E);
    cos_v = (cos_E-e) / (1-e*cos_E);
    v = atan2(sin_v, cos_v); %真近点角
    phi = v+almanac(k,6);
    sin_phi = sin(phi);
    cos_phi = cos(phi);
    r = a*(1-e*cos_E);
    xp = r*cos_phi;
    yp = r*sin_phi;
    i = almanac(k,9);
    sin_i = sin(i);
    cos_i = cos(i);
    Omega = almanac(k,7) + (almanac(k,8)-w)*dt - w*toe;
    sin_Omega = sin(Omega);
    cos_Omega = cos(Omega);
    x = xp*cos_Omega - yp*cos_i*sin_Omega;
    y = xp*sin_Omega + yp*cos_i*cos_Omega;
    z = yp*sin_i;
    
    d_E = n/(1-e*cos_E);
    d_phi = sqrt(1-e^2)*d_E/(1-e*cos_E);
    d_r = a*e*sin_E*d_E;
    d_Omega = almanac(k,8)-w;
    d_xp = d_r*cos_phi - r*sin_phi*d_phi;
    d_yp = d_r*sin_phi + r*cos_phi*d_phi;
    vx = d_xp*cos_Omega - d_yp*cos_i*sin_Omega - y*d_Omega;
    vy = d_xp*sin_Omega + d_yp*cos_i*cos_Omega + x*d_Omega;
    vz = d_yp*sin_i;
    
    rsvs(k,:) = [x,y,z,vx,vy,vz];
end

end