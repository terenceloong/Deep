function result = aziele_almanac(almanac, t, p)
% 用历书计算卫星的方位角高度角,可以处理一个历书,也可以是一组
% almanac:[week, toe, af0, af1, sqa, e, M0, omega, Omega0, Omega_dot, i],11个数
% t:[week,second]
% p:[lat,lon,h],deg,接收机位置
% result:[azi,ele],deg

miu = 3.986005e14;
w = 7.2921151467e-5;

Cen = dcmecef2ned(p(1), p(2));
rp = lla2ecef(p)'; %接收机ecef坐标

toe = almanac(1,2);
week = mod(t(1),1024); %周数取模
tk = (week-almanac(1,1))*604800 + (t(2)-toe);

N = size(almanac,1); %卫星个数
result = zeros(N,2);

for k=1:N
    %----计算卫星坐标
    a = almanac(k,5)^2;
    n = sqrt(miu/a^3);
    M = mod(almanac(k,7)+n*tk, 2*pi); %0-2*pi,平近点角
    e = almanac(k,6);
    E = kepler(M, e); %0-2*pi,偏近点角
    sin_v = sqrt(1-e^2)*sin(E) / (1-e*cos(E));
    cos_v = (cos(E)-e) / (1-e*cos(E));
    v = atan2(sin_v, cos_v); %真近点角
    phi = v+almanac(k,8);
    i = almanac(k,11);
    Omega = almanac(k,9) + (almanac(k,10)-w)*tk - w*toe;
    r = a*(1-e*cos(E));
    x = r*cos(phi);
    y = r*sin(phi);
    rs = [x*cos(Omega)-y*cos(i)*sin(Omega);
          x*sin(Omega)+y*cos(i)*cos(Omega);
          y*sin(i)]; %卫星ecef坐标
    %----计算相对位置
    rps = rs-rp; %接收机指向卫星的位置矢量,ecef
    rpsu = rps/norm(rps); %单位矢量
    rpsu_n = Cen*rpsu; %转到地理系下
    %----计算方位角高度角
    result(k,1) = atan2d(rpsu_n(2),rpsu_n(1)); %方位角,deg
    result(k,2) = asind(-rpsu_n(3)); %高度角,deg
end

end