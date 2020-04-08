function pos_tight(obj)
% 紧组合模式定位

% 获取卫星测量信息
satmeas = obj.get_satmeas;

% 获取通道信息
chN = obj.chN;
quality = zeros(chN,1); %信号质量
R_rho = zeros(chN,1); %伪距测量噪声方差,m^2
R_rhodot = zeros(chN,1); %伪距率测量噪声方差,(m/s)^2
for k=1:chN
    channel = obj.channels(k);
    if channel.state==2 %通道可以测量伪距伪距率
        quality(k) = channel.quality;
        R_rho(k) = 4^2;
        R_rhodot(k) = 0.04^2;
    end
end

% 卫星导航解算
sv = satmeas(quality>=1,:); %选星
satnav = satnavSolve(sv, obj.rp);

% 导航滤波
sv = [satmeas, quality, R_rho, R_rhodot];
obj.navFilter.run(obj.imu, sv);

% 更新接收机位置速度
obj.pos = obj.navFilter.pos;
obj.vel = obj.navFilter.vel;
obj.att = obj.navFilter.att;
obj.rp = obj.navFilter.rp;
obj.vp = obj.navFilter.vp;

% 接收机时钟修正
obj.deltaFreq = obj.deltaFreq + obj.navFilter.dtv;
obj.ta = obj.ta - sec2smu(obj.navFilter.dtr);

% 数据存储
obj.ns = obj.ns+1; %指向当前存储行
m = obj.ns;
obj.storage.ta(m) = obj.tp * [1;1e-3;1e-6]; %定位时间,s
obj.storage.df(m) = obj.deltaFreq;
obj.storage.satmeas(:,:,m) = satmeas;
obj.storage.satnav(m,:) = satnav([1,2,3,7,8,9,13,14]);
obj.storage.pos(m,:) = obj.pos;
obj.storage.vel(m,:) = obj.vel;
obj.storage.att(m,:) = obj.att;
obj.storage.imu(m,:) = obj.imu;
obj.storage.bias(m,:) = obj.navFilter.bias;
P = obj.navFilter.P;
obj.storage.P(m,:) = sqrt(diag(P));
Cnb = quat2dcm(obj.navFilter.quat);
P_angle = var_phi2angle(P(1:3,1:3), Cnb);
obj.storage.P(m,1:3) = sqrt(diag(P_angle));

% 更新下次定位时间
obj.tp(1) = NaN;

end