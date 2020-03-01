function dtiono = Klobuchar1(iono, azi, ele, lat, lon, t)
% 根据Klobuchar模型计算电离层延迟
% 参考GPS接口文档
% azi,ele:卫星方位角高度角,deg
% lat,lon:接收机纬度经度,deg
% t:周内秒数
% dtiono:电离层延迟,s
% 如果算其他频率信号的电离层延迟,乘以(f1^2/f2^2),电离层延迟与频率的平方成反比

alpha = iono(1:4);
beta = iono(5:8);

% 将方位角高度角,纬度经度单位从度转为半周
A = azi/180;
E = ele/180;
lat_u = lat/180;
lon_u = lon/180;

% 计算电离层穿刺点位置
psi = 0.0137/(E+0.11) - 0.022; %接收机位置与电离层穿刺点的地心张角,半周
lat_i = lat_u + psi*cospi(A); %电离层穿刺点的地理纬度,半周
if lat_i>0.416
    lat_i = 0.416;
elseif lat_i<-0.416
    lat_i = -0.416;
end
lon_i = lon_u + psi*sinpi(A)/cospi(lat_i); %电离层穿刺点的地理经度,半周
lat_m = lat_i + 0.064*cospi(lon_i-1.617); %电离层穿刺点的地磁纬度,半周

% 计算幅值(峰值)
AMP = alpha * [1;lat_m;lat_m^2;lat_m^3];
if AMP<0
    AMP = 0;
end

% 计算周期
PER = beta * [1;lat_m;lat_m^2;lat_m^3];
if PER<72000
    PER = 72000; %最小20小时
end

% 计算时间
t = 43200*lon_i + t; %计算电离层穿刺点的本地时间,43200=12*3600
t = mod(t,86400); %取模,在一天之内,86400=24*3600
x = 2*(t-50400)/PER; %rad,50400=14*3600,下午2点为电离层延迟峰值
% 因为突起边界为pi/2,PER最小为20小时,所以突起半宽度最少为5小时

% 计算电离层延迟
F = 1 + 16*(0.53-E)^3;
if abs(x)<0.5
    dtiono = F*(5e-9 + AMP*cospi(x));
else
    dtiono = F*5e-9;
end

end