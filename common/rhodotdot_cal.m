function rhodotdot = rhodotdot_cal(rsvsas, rp)
% 计算卫星运动引起的伪距率变化率
% rsvsas:卫星ecef位置速度加速度,[x,y,z,vx,vy,vz,ax,ay,az]
% rp:接收机ecef位置

rs = rsvsas(1:3);
vs = rsvsas(4:6);
as = rsvsas(7:9);
rps = rs - rp; %接收机指向卫星位置矢量
R = norm(rps); %接收机到卫星的距离
rhodotdot = (as*rps'+vs*vs'-(vs*rps'/R)^2) / R;

end