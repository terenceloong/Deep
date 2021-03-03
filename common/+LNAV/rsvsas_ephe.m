function [rsvsas, dtrel] = rsvsas_ephe(ephe, t)
% 使用星历计算卫星位置速度加速度(单颗卫星)
% ephe:16参数星历
% [toe,sqa,e,dn,M0,omega,Omega0,Omega_dot,i0,i_dot,Cus,Cuc,Crs,Crc,Cis,Cic]
% t:周内秒数
% rsvsas:[x,y,z,vx,vy,vz,ax,ay,az]
% dtrel:相对论钟差,s

% 检查星历参数个数
if length(ephe)~=16
    error('Ephemeris error!')
end

% 地球参数
miu = 3.986005e14;
w = 7.2921151467e-5;
F = -4.442807633e-10;

% 提取星历参数
toe = ephe(1);
sqa = ephe(2);
e = ephe(3);
dn = ephe(4);
M0 = ephe(5);
omega = ephe(6);
Omega0 = ephe(7);
Omega_dot = ephe(8);
i0 = ephe(9);
i_dot = ephe(10);
Cus = ephe(11);
Cuc = ephe(12);
Crs = ephe(13);
Crc = ephe(14);
Cis = ephe(15);
Cic = ephe(16);

%% 计算卫星位置
dt = mod(t-toe+302400,604800)-302400; %限制在±302400
a = sqa^2;
n = sqrt(miu/a^3) + dn;
M = mod(M0+n*dt, 2*pi); %0-2*pi,平近点角
E = kepler(M, e); %0-2*pi,偏近点角
sin_E = sin(E);
cos_E = cos(E);
sin_v = sqrt(1-e^2)*sin_E; % / (1-e*cos_E);
cos_v = (cos_E-e); % / (1-e*cos_E);
v = atan2(sin_v, cos_v); %真近点角
phi = v + omega;
sin_2phi = sin(2*phi);
cos_2phi = cos(2*phi);
du = Cus*sin_2phi + Cuc*cos_2phi;
dr = Crs*sin_2phi + Crc*cos_2phi;
di = Cis*sin_2phi + Cic*cos_2phi;
u = phi + du;
sin_u = sin(u);
cos_u = cos(u);
r = a*(1-e*cos_E) + dr;
xp = r*cos_u;
yp = r*sin_u;
i = i0 + i_dot*dt + di;
sin_i = sin(i);
cos_i = cos(i);
Omega = Omega0 + (Omega_dot-w)*dt - w*toe;
sin_Omega = sin(Omega);
cos_Omega = cos(Omega);
x = xp*cos_Omega - yp*cos_i*sin_Omega;
y = xp*sin_Omega + yp*cos_i*cos_Omega;
z = yp*sin_i;

%% 计算卫星速度
% <北斗/GPS双模软件接收机原理与实现技术>283页
d_E = n/(1-e*cos_E);
d_phi = sqrt(1-e^2)*d_E/(1-e*cos_E);
d_r = a*e*sin_E*d_E + 2*(Crs*cos_2phi-Crc*sin_2phi)*d_phi;
d_u = d_phi + 2*(Cus*cos_2phi-Cuc*sin_2phi)*d_phi;
d_Omega = Omega_dot-w;
d_i = i_dot + 2*(Cis*cos_2phi-Cic*sin_2phi)*d_phi;
d_xp = d_r*cos_u - r*sin_u*d_u;
d_yp = d_r*sin_u + r*cos_u*d_u;
vx = d_xp*cos_Omega - d_yp*cos_i*sin_Omega + yp*sin_i*sin_Omega*d_i - y*d_Omega;
vy = d_xp*sin_Omega + d_yp*cos_i*cos_Omega - yp*sin_i*cos_Omega*d_i + x*d_Omega;
vz = d_yp*sin_i + yp*cos_i*d_i;

%% 输出
rsvsas = [x,y,z,vx,vy,vz,0,0,0];
dtrel = F*e*sqa*sin_E;

%% 计算卫星加速度
T = 0.1; %差分时间间隔

% 根据之前算出的导数用差分方法计算新的轨道参数
x = x + vx*T;
y = y + vy*T;
E = E + d_E*T;
sin_E = sin(E);
cos_E = cos(E);
phi = phi + d_phi*T;
sin_2phi = sin(2*phi);
cos_2phi = cos(2*phi);
r = r + d_r*T;
u = u + d_u*T;
sin_u = sin(u);
cos_u = cos(u);
Omega = Omega + d_Omega*T;
sin_Omega = sin(Omega);
cos_Omega = cos(Omega);
i = i + d_i*T;
sin_i = sin(i);
cos_i = cos(i);
yp = r*sin_u;

% 用新的轨道参数计算速度
d_E = n/(1-e*cos_E);
d_phi = sqrt(1-e^2)*d_E/(1-e*cos_E);
d_r = a*e*sin_E*d_E + 2*(Crs*cos_2phi-Crc*sin_2phi)*d_phi;
d_u = d_phi + 2*(Cus*cos_2phi-Cuc*sin_2phi)*d_phi;
d_i = i_dot + 2*(Cis*cos_2phi-Cic*sin_2phi)*d_phi;
d_xp = d_r*cos_u - r*sin_u*d_u;
d_yp = d_r*sin_u + r*cos_u*d_u;
vx1 = d_xp*cos_Omega - d_yp*cos_i*sin_Omega + yp*sin_i*sin_Omega*d_i - y*d_Omega;
vy1 = d_xp*sin_Omega + d_yp*cos_i*cos_Omega - yp*sin_i*cos_Omega*d_i + x*d_Omega;
vz1 = d_yp*sin_i + yp*cos_i*d_i;

% 速度差分得到加速度
ax = (vx1-vx)/T;
ay = (vy1-vy)/T;
az = (vz1-vz)/T;

%% 输出
% rsvsas(7:9) = [ax,ay,az]; %这么写比下面的慢一些
rsvsas(7) = ax;
rsvsas(8) = ay;
rsvsas(9) = az;

end