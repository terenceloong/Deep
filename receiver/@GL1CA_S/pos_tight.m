function pos_tight(obj)
% 紧组合定位

% 获取卫星测量信息
satmeas = obj.get_satmeas;

% 高度角引起的误差
[~, ele] = aziele_xyz(satmeas(:,1:3), obj.pos); %卫星高度角
eleError = 5*(1-1./(1+exp(-((ele-30)/5))));

% 获取通道信息
chN = obj.chN;
CN0 = zeros(chN,1); %载噪比
R_rho = zeros(chN,1); %伪距测量噪声方差,m^2
R_rhodot = zeros(chN,1); %伪距率测量噪声方差,(m/s)^2
R_phase = zeros(chN,1); %载波相位测量噪声方差,(circ)^2
for k=1:chN
    channel = obj.channels(k);
    if channel.state==2
        CN0(k) = channel.CN0;
        R_rho(k) = (sqrt(channel.varValue(1))+eleError(k))^2;
        R_rhodot(k) = channel.varValue(2);
        R_phase(k) = channel.varValue(4);
    end
end
sv = [satmeas(:,1:8), R_rho, R_rhodot];

% 卫星导航解算
svIndex = CN0>=obj.CN0Thr.strong; %选星
satnav = satnavSolveWeighted(sv(svIndex,:), obj.rp);

% 导航滤波
indexP = CN0>=obj.CN0Thr.middle; %使用伪距的索引
indexV = CN0>=obj.CN0Thr.strong; %使用伪距率的索引
obj.navFilter.run(obj.imu, sv, indexP, indexV);

% 计算地理系下杆臂位置速度
Cnb = quat2dcm(obj.navFilter.quat);
Cen = dcmecef2ned(obj.navFilter.pos(1), obj.navFilter.pos(2));
arm = obj.navFilter.arm; %体系下杆臂矢量
wb = obj.imu(1:3) - obj.navFilter.bias(1:3); %角速度,rad/s
r_arm = arm*Cnb;
v_arm = cross(wb,arm)*Cnb;

% 更新接收机位置速度
obj.pos = obj.navFilter.pos + r_arm*obj.navFilter.geogInfo.Cn2g;
obj.vel = obj.navFilter.vel + v_arm;
obj.att = obj.navFilter.att;
obj.rp = lla2ecef(obj.pos);
obj.vp = obj.vel*Cen;
obj.geogInfo = geogInfo_cal(obj.pos, obj.vel);

% 接收机时钟修正
obj.deltaFreq = obj.deltaFreq + obj.navFilter.dtv;
obj.navFilter.dtv = 0;
obj.ta = obj.ta - sec2smu(obj.navFilter.dtr);
obj.clockError = obj.clockError + obj.navFilter.dtr;
obj.navFilter.dtr = 0;

% 数据存储
obj.ns = obj.ns+1; %指向当前存储行
m = obj.ns;
obj.storage.ta(m) = obj.tp * [1;1e-3;1e-6]; %定位时间,s
obj.storage.df(m) = obj.deltaFreq;
obj.storage.satmeas(:,1:10,m) = sv;
obj.storage.satmeas(:,11,m) = satmeas(:,9); %载波相位
obj.storage.satmeas(:,12,m) = R_phase;
obj.storage.satnav(m,:) = satnav([1,2,3,7,8,9,13,14]);
obj.storage.svsel(m,:) = indexP + indexV;
obj.storage.pos(m,:) = obj.pos;
obj.storage.vel(m,:) = obj.vel;
obj.storage.att(m,:) = obj.att;
obj.storage.imu(m,:) = obj.imu;
obj.storage.bias(m,:) = obj.navFilter.bias;
P = obj.navFilter.P;
obj.storage.P(m,1:size(P,1)) = sqrt(diag(P));
Cnb = quat2dcm(obj.navFilter.quat);
P_angle = var_phi2angle(P(1:3,1:3), Cnb);
obj.storage.P(m,1:3) = sqrt(diag(P_angle));
obj.storage.motion(m) = obj.navFilter.motion.state;

% 更新下次定位时间
obj.tp(1) = NaN;

end