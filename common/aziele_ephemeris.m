function result = aziele_ephemeris(ephemeris, t, p)
% 用星历计算卫星的方位角高度角,可以是一个星历,也可以是一组星历
% ephemeris:16参数,[toe,sqa,e,dn,M0,omega,Omega0,Omega_dot,i0,i_dot,Cus,Cuc,Crs,Crc,Cis,Cic]
% t:周内秒数
% p:[lat,lon,h],deg,接收机位置
% result:[azi,ele],deg

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
toe = ephemeris(1,1);
dt = t - toe;
if dt>302400
    dt = dt-604800;
elseif dt<-302400
    dt = dt+604800;
end

% 计算
N = size(ephemeris,1); %卫星个数
result = zeros(N,2);
for k=1:N
    %----计算卫星坐标
    a = ephemeris(k,2)^2;
    n = sqrt(miu/a^3) + ephemeris(k,4);
    M = mod(ephemeris(k,5)+n*dt, 2*pi); %0-2*pi,平近点角
    e = ephemeris(k,3);
    E = kepler(M, e); %0-2*pi,偏近点角
    sin_v = sqrt(1-e^2)*sin(E) / (1-e*cos(E));
    cos_v = (cos(E)-e) / (1-e*cos(E));
    v = atan2(sin_v, cos_v); %真近点角
    phi = v+ephemeris(k,6);
    sin_2phi = sin(2*phi);
    cos_2phi = cos(2*phi);
    du = ephemeris(k,11)*sin_2phi + ephemeris(k,12)*cos_2phi;
    dr = ephemeris(k,13)*sin_2phi + ephemeris(k,14)*cos_2phi;
    di = ephemeris(k,15)*sin_2phi + ephemeris(k,16)*cos_2phi;
    u = phi + du;
    r = a*(1-e*cos(E)) + dr;
    xp = r*cos(u);
    yp = r*sin(u);
    i = ephemeris(k,9) + ephemeris(k,10)*dt + di;
    if i>0.3 %MEO/IGSO
        Omega = ephemeris(k,7) + (ephemeris(k,8)-w)*dt - w*toe;
        rs = [xp*cos(Omega)-yp*cos(i)*sin(Omega);
              xp*sin(Omega)+yp*cos(i)*cos(Omega);
              yp*sin(i)]; %卫星ecef坐标
    else %GEO
        Omega = ephemeris(k,7) + ephemeris(k,8)*dt - w*toe;
        rs = [xp*cos(Omega)-yp*cos(i)*sin(Omega);
              xp*sin(Omega)+yp*cos(i)*cos(Omega);
              yp*sin(i)]; %卫星在自定义坐标系中的坐标
        psi = -5/180*pi;
        Rx = [1,0,0; 0,cos(psi),sin(psi); 0,-sin(psi),cos(psi)];
        psi = w*dt;
        Rz = [cos(psi),sin(psi),0; -sin(psi),cos(psi),0; 0,0,1];
        rs = Rz*Rx*rs; %卫星ecef坐标
    end
    %----计算相对位置
    rps = rs-rp; %接收机指向卫星的位置矢量,ecef
    rpsu = rps/norm(rps); %单位矢量
    rpsu_n = Cen*rpsu; %转到地理系下
    %----计算方位角高度角
    result(k,1) = atan2d(rpsu_n(2),rpsu_n(1)); %方位角,deg
    result(k,2) = asind(-rpsu_n(3)); %高度角,deg
end

end