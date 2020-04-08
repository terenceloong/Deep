function [rho, rhodot, rspu, Cen] = rho_rhodot_cal_geog(rs, vs, pos, vel)
% 使用接收机的纬经高地理系速度计算理论相对距离相对速度(多颗卫星)
% rs:卫星ecef位置
% vs:卫星ecef速度
% pos:接收机纬经高,deg
% vel:接收机地理系速度,北东地
% rho:理论相对距离
% rhodot:理论相对速度
% rspu:ecef系下卫星指向接收机的单位矢量
% Cen:ecef到地理系的坐标变换阵

n = size(rs,1); %卫星个数

% 计算相对距离
rp = lla2ecef(pos);
rsp = ones(n,1)*rp - rs; %卫星指向接收机
rho = vecnorm(rsp,2,2);
rspu = rsp ./ (rho*[1,1,1]);

% 计算相对速度
Cen = dcmecef2ned(pos(1),pos(2));
vp = vel*Cen;
vsp = ones(n,1)*vp - vs; %接收机相对卫星的速度
rhodot = sum(vsp.*rspu,2);

end