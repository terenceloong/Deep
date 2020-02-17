function p = lla2ecef(lla)
% 纬经高坐标转化为ecef坐标(这是简单的)
% lla单位:deg

a = 6378137;
f = 1/298.257223563;
e2 = f*(2-f);

sinlat = sind(lla(1));
coslat = cosd(lla(1));
sinlon = sind(lla(2));
coslon = cosd(lla(2)); 
h = lla(3);

N = a / sqrt(1-e2*sinlat^2);
rho = (N+h) * coslat;
x = rho * coslon;
y = rho * sinlon;
z = (N*(1-e2)+h) * sinlat;
p = [x,y,z];

end