function rs = rs_ephe(ephe, t)
% 使用星历计算卫星ecef位置(多颗卫星)
% ephe:16参数星历,每行为1颗卫星
% [toe,sqa,e,dn,M0,omega,Omega0,Omega_dot,i0,i_dot,Cus,Cuc,Crs,Crc,Cis,Cic]
% t:周内秒数
% rs:卫星ecef位置,每行为1颗卫星

% 检查星历参数个数
[svN, paraN] = size(ephe);
if paraN~=16
    error('Ephemeris error!')
end

% 地球参数
%----GPS文档中给出的
% miu = 3.986005e14;
% w = 7.2921151467e-5;
%----WGS84文档和北斗文档给出的
miu = 3.986004418e14;
w = 7.292115e-5;

% 观测历元与参考历元的时间差
toe = ephe(1,1);
dt = mod(t-toe+302400,604800)-302400; %限制在±302400

% 计算所有卫星ecef位置
rs = zeros(svN,3);
for k=1:svN
    a = ephe(k,2)^2;
    n = sqrt(miu/a^3) + ephe(k,4);
    M = mod(ephe(k,5)+n*dt, 2*pi); %0-2*pi,平近点角
    e = ephe(k,3);
    E = kepler(M, e); %0-2*pi,偏近点角
    sin_v = sqrt(1-e^2)*sin(E) / (1-e*cos(E));
    cos_v = (cos(E)-e) / (1-e*cos(E));
    v = atan2(sin_v, cos_v); %真近点角
    phi = v+ephe(k,6);
    sin_2phi = sin(2*phi);
    cos_2phi = cos(2*phi);
    du = ephe(k,11)*sin_2phi + ephe(k,12)*cos_2phi;
    dr = ephe(k,13)*sin_2phi + ephe(k,14)*cos_2phi;
    di = ephe(k,15)*sin_2phi + ephe(k,16)*cos_2phi;
    u = phi + du;
    r = a*(1-e*cos(E)) + dr;
    xp = r*cos(u);
    yp = r*sin(u);
    i = ephe(k,9) + ephe(k,10)*dt + di;
    if i>0.3 %MEO/IGSO
        Omega = ephe(k,7) + (ephe(k,8)-w)*dt - w*toe;
        rs(k,1) = xp*cos(Omega) - yp*cos(i)*sin(Omega);
        rs(k,2) = xp*sin(Omega) + yp*cos(i)*cos(Omega);
        rs(k,3) = yp*sin(i);
    else %GEO
        Omega = ephe(k,7) + ephe(k,8)*dt - w*toe;
        rs0 = [xp*cos(Omega) - yp*cos(i)*sin(Omega);
               xp*sin(Omega) + yp*cos(i)*cos(Omega);
               yp*sin(i)]; %卫星在自定义坐标系中的坐标
        psi = -5/180*pi;
        Rx = [1,0,0; 0,cos(psi),sin(psi); 0,-sin(psi),cos(psi)];
        psi = w*dt;
        Rz = [cos(psi),sin(psi),0; -sin(psi),cos(psi),0; 0,0,1];
        rs(k,:) = Rz*Rx*rs0;
    end
end

end