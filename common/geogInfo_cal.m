function geogInfo = geogInfo_cal(lla, vel)
% 给定纬经高和地理系速度计算地理信息

lat = lla(1); %deg
lon = lla(2); %deg
h = lla(3);
sin_lat = sind(lat);
cos_lat = cosd(lat);
[Rm, Rn] = earthCurveRadius(lat);
dlatdn = 1/(Rm+h);
dlonde = 1/((Rn+h)*cos_lat); %经度对东向位移的导数
Cen = dcmecef2ned(lat, lon);
wien = [cos_lat, 0, -sin_lat] * 7.292115e-5;
wenn = [vel(2)*dlonde*cos_lat, -vel(1)*dlatdn, -vel(2)*dlonde*sin_lat];
wiee = [0 ,0, 7.292115e-5];
wene = wenn*Cen;
g = gravitywgs84(h, lat);

geogInfo.Rm = Rm; %子午圈半径(不含高度)
geogInfo.Rn = Rn; %卯酉圈半径(不含高度)
geogInfo.dlatdn = dlatdn; %纬度对北向位移的导数(含高度)
geogInfo.dlonde = dlonde; %经度对东向位移的导数(含高度)
geogInfo.Cn2g = diag([dlatdn/pi*180, dlonde/pi*180, -1]); %地理系位移转成经纬度的矩阵
geogInfo.wien = wien;
geogInfo.wenn = wenn;
geogInfo.wiee = wiee;
geogInfo.wene = wene;
geogInfo.g = g; %重力加速度,m/s^2

end