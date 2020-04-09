function pos_deep(obj)
% 深组合定位

% 波长
lamdaCarr = 299792458/1575.42e6; %载波长,m
lamdaCode = 299792458/1.023e6; %码长,m

% 获取卫星测量信息
satmeas = obj.get_satmeas;

% 获取通道信息
chN = obj.chN;
quality = zeros(chN,1); %信号质量
codeDisc = zeros(chN,1); %定位间隔内码鉴相器输出的平均值,m
R_rho = zeros(chN,1); %伪距测量噪声方差,m^2
R_rhodot = zeros(chN,1); %伪距率测量噪声方差,(m/s)^2
for k=1:chN
    channel = obj.channels(k);
    if channel.state==3
        quality(k) = channel.quality;
        [co, ~] = channel.getDiscOutput;
        codeDisc(k) = mean(co)*lamdaCode;
        R_rho(k) = 4^2;
        R_rhodot(k) = 0.04^2;
    end
end

% 卫星导航解算
sv = satmeas(quality>=1,:); %选星
satnav = satnavSolve(sv, obj.rp);

% 导航滤波
sv = [satmeas, quality, R_rho, R_rhodot];
sv(:,7) = sv(:,7) - codeDisc; %本地码超前,伪距偏短,码鉴相器为负,修正是减
obj.navFilter.run(obj.imu, sv);

% 码相位误差和载波频率误差(通道值减真实值)
[rho0, rhodot0] = rho_rhodot_cal_ecef(satmeas(:,1:3), satmeas(:,4:6), ...
                  obj.navFilter.rp, obj.navFilter.vp);
dcodePhase = (rho0-satmeas(:,7))/lamdaCode; %伪距短,码相位超前
dcarrFreq = (rhodot0-satmeas(:,8))/lamdaCarr; %伪距率小,载波频率快

% 通道修正
switch obj.deepMode
    case 1
        for k=1:chN
            channel = obj.channels(k);
            if channel.state==3
                channel.remCodePhase = channel.remCodePhase - dcodePhase(k);
                channel.markCurrStorage;
            end
        end
    case 2
end

% 新跟踪的通道切换深组合跟踪环路
obj.channel_deep;

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