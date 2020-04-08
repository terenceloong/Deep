function F = jacobi_lla2ecef(lat, lon, h, Rn)
% 纬经高坐标到ecef坐标的雅可比矩阵
% 经纬度单位deg

sinlat = sind(lat);
coslat = cosd(lat);
sinlon = sind(lon);
coslon = cosd(lon);

f = 1/298.257223563;
F = [-(Rn+h)*sinlat*coslon, -(Rn+h)*coslat*sinlon, coslat*coslon;
     -(Rn+h)*sinlat*sinlon,  (Rn+h)*coslat*coslon, coslat*sinlon;
     (Rn*(1-f)^2+h)*coslat,             0,         sinlat];

end