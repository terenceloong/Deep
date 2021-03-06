function g = gravitywgs84(h, lat)
% 重力模型参见WGS84手册4-1
% 跟gravitywgs84计算结果完全一样
% 纬度单位:deg

sin_lat_2 = sind(lat)^2;
r = 9.7803253359 * (1+0.00193185265241*sin_lat_2) / (1-0.00669437999014*sin_lat_2)^0.5;
g = r * (1 - 3.135711885774796e-07*(1.006802597171588-0.006705621329495*sin_lat_2)*h + 7.374516772941995e-14*h^2);

% a = 6378137;
% f = 1/298.257223563;
% w = 7.292115e-5;
% GM = 3.986004418e14;
% re = 9.7803253359;
% rp = 9.8321849378;

% b = (1-f)*a;
% k = b*rp/(a*re)-1;
% m = w*w*a*a*b/GM;
% e2 = f*(2-f);

% b = 6356752.3142;
% k = 0.00193185265241;
% m = 0.00344978650684;
% e2 = 6.69437999014e-3;

% r = re * (1+k*sind(lat)^2) / (1-e2*sind(lat)^2)^0.5;
% g = r * (1 - 2/a*(1+f+m-2*f*sind(lat)^2)*h + 3/a^2*h^2);

end