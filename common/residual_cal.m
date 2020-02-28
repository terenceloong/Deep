function [res_rho, res_rhodot] = residual_cal(satmeas, satnav)
% 计算残差
% satmeas:卫星测量,[x,y,z,vx,vy,vz,rho,rhodot]
% satnav:卫星导航结果,[x,y,z,vx,vy,vz,dtr,dtv]
% res_rho:伪距残差,测量减计算,列向量
% res_rhodot:伪距率残差,测量减计算,列向量

rs = satmeas(:,1:3);
vs = satmeas(:,4:6);
rho = satmeas(:,7); %测量的伪距
rhodot = satmeas(:,8); %测量的伪距率

rp = satnav(1:3);
vp = satnav(4:6);
dtr = satnav(7);
dtv = satnav(8);

n = size(satmeas,1); %卫星个数
rps = rs - ones(n,1)*rp; %接收机指向卫星位置矢量
R = vecnorm(rps,2,2); %各行取模,接收机到卫星的理论距离
rpsu = rps ./ (R*[1,1,1]); %接收机指向卫星视线单位矢量
vps = vs - ones(n,1)*vp; %卫星相对接收机的速度
V = sum(vps.*rpsu,2); %相对速度往视线矢量上投影,理论距离变化率

c = 299792458;
res_rho = rho - R - dtr*c; %伪距残差
res_rhodot = rhodot - V - dtv*c; %伪距率残差

end