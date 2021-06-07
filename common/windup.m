function [phi, phidot] = windup(as, bs, k, wb, Ceb)
% 计算相位缠绕效应引起的相位误差和频率误差,[周,Hz]
% as:卫星本体系的x轴单位矢量
% bs:卫星本体系的y轴单位矢量
% k:卫星指向天线的视线单位矢量
% wb:天线旋转角速度,rad/s
% Ceb:ecef系到天线本体系的坐标变换阵

% 接收机天线偶极子
ar = [0,1,0]*Ceb; %东向
br = [1,0,0]*Ceb; %北向
Dr = ar - k*(k*ar') + cross(k,br);
Drm = norm(Dr);

% 卫星天线偶极子
Ds = as - k*(k*as') - cross(k,bs);
Dsm = norm(Ds);

% 正负号
zeta = k*cross(Ds,Dr)';

% cos(phi)
cos_phi = Ds*Dr' / (Dsm*Drm);

% phi
phi = sign(zeta) * acos(cos_phi);
phi = phi/2/pi; %周

% Drdot
ardot = cross(wb,[0,1,0])*Ceb;
brdot = cross(wb,[1,0,0])*Ceb;
Drdot = ardot - k*(k*ardot') + cross(k,brdot);

% phidot
phidot = sign(zeta) * -1/sqrt(1-cos_phi^2) * (Ds/Dsm) * (Drdot/Drm-(Dr*Drdot')*Dr/Drm^3)';
% phidot = sign(zeta) * -1/sqrt(1-cos_phi^2) * (Ds/Dsm) * (cross(Dr,cross(Drdot,Dr))/Drm^3)';
phidot = phidot/2/pi; %Hz

end