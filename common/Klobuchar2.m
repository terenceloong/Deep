function dtiono = Klobuchar2(iono, azi, ele, lat, lon, t)
% 根据Klobuchar模型计算电离层延迟
% 参考BDS接口文档,<ESA_GNSS-Book_TM-23_Vol_I>P117
% azi,ele:卫星方位角高度角,deg
% lat,lon:接收机纬度经度,deg
% t:周内秒数
% dtiono:电离层延迟,s
% 如果算其他频率信号的电离层延迟,乘以(f1^2/f2^2),电离层延迟与频率的平方成反比

alpha = iono(1:4);
beta = iono(5:8);

R = 6378/(6378+350);

% 将方位角高度角,纬度经度单位从度转为弧度
A = azi/180*pi;
E = ele/180*pi;
lat_u = lat/180*pi;
lon_u = lon/180*pi;

% 计算电离层穿刺点位置
% 接收机位置与电离层穿刺点的地心张角,rad
psi = pi/2 - E - asin(R*cos(E));
% 电离层穿刺点的地理纬度,rad
lat_i = asin(sin(lat_u)*cos(psi)+cos(lat_u)*sin(psi)*cos(A));
% 电离层穿刺点的地理经度,rad
lon_i = lon_u + psi*sin(A)/cos(lat_i);
% 电离层穿刺点的地磁纬度rad
lat_m = asin(sin(lat_i)*sind(78.3)+cos(lat_i)*cosd(78.3)*cos(lon_i-291/180*pi));
lat_m = lat_m/pi; %半周

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
t = 43200*lon_i/pi + t; %计算电离层穿刺点的本地时间,43200=12*3600
t = mod(t,86400); %取模,在一天之内,86400=24*3600
x = 2*(t-50400)/PER; %rad,50400=14*3600,下午2点为电离层延迟峰值
% 因为突起边界为pi/2,PER最小为20小时,所以突起半宽度最少为5小时

% 计算电离层延迟
F = 1/sqrt(1-(R*cos(E))^2);
if abs(x)<0.5
    dtiono = F*(5e-9 + AMP*cospi(x));
else
    dtiono = F*5e-9;
end

end