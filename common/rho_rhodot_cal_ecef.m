function [rho, rhodot, rspu] = rho_rhodot_cal_ecef(rs, vs, rp, vp)
% 使用接收机的ecef位置速度计算理论相对距离相对速度(多颗卫星)

n = size(rs,1); %卫星个数

% 计算相对距离
rsp = ones(n,1)*rp - rs; %卫星指向接收机
rho = vecnorm(rsp,2,2);
rspu = rsp ./ (rho*[1,1,1]);

% 计算相对速度
vsp = ones(n,1)*vp - vs; %接收机相对卫星的速度
rhodot = sum(vsp.*rspu,2);

end