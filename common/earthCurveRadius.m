function [Rm, Rn] = earthCurveRadius(lat)
% 计算地球子午圈,卯酉圈曲率半径
% lat:纬度,deg

sin_lat_2 = sind(lat)^2;
Rm = 6335439.32729282 / (1-0.006694379990141*sin_lat_2)^1.5;
Rn = 6378137.00000000 / (1-0.006694379990141*sin_lat_2)^0.5;

% a = 6378137;
% f = 1/298.257223563;

% Rm = (1-f)^2*a / (1-(2-f)*f*sind(lat)^2)^1.5;
% Rn =         a / (1-(2-f)*f*sind(lat)^2)^0.5;

end