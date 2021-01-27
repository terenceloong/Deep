function rhodotdot = rhodotdot_cal(rsvsas, rp, vp, geogInfo)
% 计算卫星运动引起的相对加速度(一颗卫星)
% rsvsas:卫星ecef位置速度加速度,[x,y,z,vx,vy,vz,ax,ay,az]
% rp:接收机ecef位置
% vp:接收机ecef速度
% geogInfo:地理信息

rs = rsvsas(1:3);
vs = rsvsas(4:6);
as = rsvsas(7:9);
ap = cross(geogInfo.wene,vp); %根据哥氏定理,地理系旋转引起的附加加速度
rps = rs - rp; %接收机指向卫星位置矢量
vps = vs - vp;
aps = as - ap;
R = norm(rps); %接收机到卫星的距离
rhodotdot = (aps*rps'+vps*vps'-(vps*rps'/R)^2) / R;

end