function pos_tight(obj)
% 紧组合定位

% 获取卫星测量信息 & 获取通道信息 & 单独卫星导航解算
if obj.GPSflag==1
    satmeasGPS = obj.get_satmeasGPS; %卫星测量信息
    [~, ele] = aziele_xyz(satmeasGPS(:,1:3), obj.pos); %卫星高度角
    eleError = 5*(1-1./(1+exp(-((ele-30)/5)))); %高度角引起的误差
    %---------------------------------------------------------------------%
    chN = obj.GPS.chN;
    CN0 = zeros(chN,1); %载噪比
    R_rho = zeros(chN,1); %伪距测量噪声方差,m^2
    R_rhodot = zeros(chN,1); %伪距率测量噪声方差,(m/s)^2
    for k=1:chN
        channel = obj.GPS.channels(k);
        if channel.state==2
            CN0(k) = channel.CN0;
            R_rho(k) = (sqrt(channel.varValue(1))+eleError(k))^2;
            R_rhodot(k) = channel.varValue(2);
        end
    end
    svGPS = [satmeasGPS(:,1:8), R_rho, R_rhodot];
    %---------------------------------------------------------------------%
    svIndexGPS = CN0>=obj.CN0Thr.strong; %选星
    satnavGPS = satnavSolveWeighted(svGPS(svIndexGPS,:), obj.rp);
    indexP_GPS = CN0>=obj.CN0Thr.middle; %使用伪距的索引
    indexV_GPS = CN0>=obj.CN0Thr.strong; %使用伪距率的索引
end
if obj.BDSflag==1
    satmeasBDS = obj.get_satmeasBDS; %卫星测量信息
    [~, ele] = aziele_xyz(satmeasBDS(:,1:3), obj.pos); %卫星高度角
    eleError = 5*(1-1./(1+exp(-((ele-30)/5)))); %高度角引起的误差
    %---------------------------------------------------------------------%
    chN = obj.BDS.chN;
    CN0 = zeros(chN,1); %载噪比
    R_rho = zeros(chN,1); %伪距测量噪声方差,m^2
    R_rhodot = zeros(chN,1); %伪距率测量噪声方差,(m/s)^2
    for k=1:chN
        channel = obj.BDS.channels(k);
        if channel.state==2
            CN0(k) = channel.CN0;
            R_rho(k) = (sqrt(channel.varValue(1))+eleError(k))^2;
            R_rhodot(k) = channel.varValue(2);
        end
    end
    svBDS = [satmeasBDS(:,1:8), R_rho, R_rhodot];
    %---------------------------------------------------------------------%
    svIndexBDS = CN0>=obj.CN0Thr.strong; %选星
    satnavBDS = satnavSolveWeighted(svBDS(svIndexBDS,:), obj.rp);
    indexP_BDS = CN0>=obj.CN0Thr.middle; %使用伪距的索引
    indexV_BDS = CN0>=obj.CN0Thr.strong; %使用伪距率的索引
end

% 卫星导航解算 & 导航滤波
if obj.GPSflag==1 && obj.BDSflag==0
    satnav = satnavGPS;
    obj.navFilter.run(obj.imu, svGPS, indexP_GPS, indexV_GPS);
elseif obj.GPSflag==0 && obj.BDSflag==1
    satnav = satnavBDS;
    obj.navFilter.run(obj.imu, svBDS, indexP_BDS, indexV_BDS);
elseif obj.GPSflag==1 && obj.BDSflag==1
    sv = [svGPS; svBDS];
    svIndex = [svIndexGPS; svIndexBDS];
    satnav = satnavSolveWeighted(sv(svIndex,:), obj.rp);
    indexP = [indexP_GPS; indexP_BDS];
    indexV = [indexV_GPS; indexV_BDS];
    obj.navFilter.run(obj.imu, sv, indexP, indexV);
end

% 计算ecef系下杆臂位置速度
Cnb = quat2dcm(obj.navFilter.quat);
Cen = dcmecef2ned(obj.navFilter.pos(1), obj.navFilter.pos(2));
arm = obj.navFilter.arm; %体系下杆臂矢量
wb = obj.imu(1:3) - obj.navFilter.bias(1:3); %角速度,rad/s
r_arm = arm*Cnb*Cen;
v_arm = cross(wb,arm)*Cnb*Cen;

% 更新接收机位置速度
obj.rp = obj.navFilter.rp + r_arm;
obj.vp = obj.navFilter.vp + v_arm;
obj.att = obj.navFilter.att;
obj.pos = ecef2lla(obj.rp);
obj.vel = obj.vp*Cen';
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
obj.storage.satnav(m,:) = satnav([1,2,3,7,8,9,13,14]);
if obj.GPSflag==1
    obj.storage.satnavGPS(m,:) = satnavGPS([1,2,3,7,8,9,13,14]);
    obj.storage.svselGPS(m,:) = indexP_GPS + indexV_GPS;
end
if obj.BDSflag==1
    obj.storage.satnavBDS(m,:) = satnavBDS([1,2,3,7,8,9,13,14]);
    obj.storage.svselBDS(m,:) = indexP_BDS + indexV_BDS;
end
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