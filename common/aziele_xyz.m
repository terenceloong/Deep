function [azi, ele] = aziele_xyz(rs, lla)
% 使用卫星ecef位置计算卫星方位角高度角
% rs:卫星ecef位置,每行为1颗卫星
% lla:接收机位置,deg
% azi,ele:卫星方位角高度角,deg,列向量

Cen = dcmecef2ned(lla(1),lla(2));
rp = lla2ecef(lla); %接收机ecef位置
rps = rs - rp; %接收机指向卫星位置矢量
rho = vecnorm(rps,2,2); %相对每颗卫星的距离
rpsu = rps ./ (rho*[1,1,1]); %接收机指向卫星的视线单位矢量
rpsu_n = rpsu*Cen'; %视线矢量转到地理系下
azi = atan2d(rpsu_n(:,2),rpsu_n(:,1));
azi = mod(azi,360); %0~360度
ele = asind(-rpsu_n(:,3));

end