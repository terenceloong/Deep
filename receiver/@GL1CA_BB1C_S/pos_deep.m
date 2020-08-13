function pos_deep(obj)
% 深组合定位

% 波长
Lca = 299792458/1575.42e6; %载波长,m
Lco = 299792458/1.023e6; %码长,m

%% 不加权
% % 获取卫星测量信息 & 获取通道信息 & 单独卫星导航解算
% if obj.GPSflag==1
%     satmeasGPS = obj.get_satmeasGPS; %卫星测量信息
%     %---------------------------------------------------------------------%
%     chN = obj.GPS.chN;
%     quality = zeros(chN,1); %信号质量
%     codeDisc = zeros(chN,1); %定位间隔内码鉴相器输出的平均值,m
%     R_rho = zeros(chN,1); %伪距测量噪声方差,m^2
%     R_rhodot = zeros(chN,1); %伪距率测量噪声方差,(m/s)^2
%     for k=1:chN
%         channel = obj.GPS.channels(k);
%         if channel.state==3
%             quality(k) = channel.quality;
%             [co, ~] = channel.getDiscOutput;
%             codeDisc(k) = sum(co)/length(co)*Lco;
%             R_rho(k) = 4^2;
%             R_rhodot(k) = 0.04^2;
%         end
%     end
%     svGPS = [satmeasGPS, quality, R_rho, R_rhodot]; %带信号质量评价的卫星测量信息
%     svGPS(:,7) = svGPS(:,7) - codeDisc; %本地码超前,伪距偏短,码鉴相器为负,修正是减
%     %---------------------------------------------------------------------%
%     sv = svGPS(svGPS(:,9)>=1,1:8); %选信号质量不为0的卫星
%     satnavGPS = satnavSolve(sv, obj.rp);
% end
% if obj.BDSflag==1
%     satmeasBDS = obj.get_satmeasBDS; %卫星测量信息
%     %---------------------------------------------------------------------%
%     chN = obj.BDS.chN;
%     quality = zeros(chN,1); %信号质量
%     codeDisc = zeros(chN,1); %定位间隔内码鉴相器输出的平均值,m
%     R_rho = zeros(chN,1); %伪距测量噪声方差,m^2
%     R_rhodot = zeros(chN,1); %伪距率测量噪声方差,(m/s)^2
%     for k=1:chN
%         channel = obj.BDS.channels(k);
%         if channel.state==3
%             quality(k) = channel.quality;
%             [co, ~] = channel.getDiscOutput;
%             codeDisc(k) = sum(co)/length(co)*Lco;
%             R_rho(k) = 4^2;
%             R_rhodot(k) = 0.04^2;
%         end
%     end
%     svBDS = [satmeasBDS, quality, R_rho, R_rhodot]; %带信号质量评价的卫星测量信息
%     svBDS(:,7) = svBDS(:,7) - codeDisc; %本地码超前,伪距偏短,码鉴相器为负,修正是减
%     %---------------------------------------------------------------------%
%     sv = svBDS(svBDS(:,9)>=1,1:8); %选信号质量不为0的卫星
%     satnavBDS = satnavSolve(sv, obj.rp);
% end
% 
% % 卫星导航解算 & 导航滤波
% if obj.GPSflag==1 && obj.BDSflag==0
%     satnav = satnavGPS;
%     obj.navFilter.run(obj.imu, svGPS);
% elseif obj.GPSflag==0 && obj.BDSflag==1
%     satnav = satnavBDS;
%     obj.navFilter.run(obj.imu, svBDS);
% elseif obj.GPSflag==1 && obj.BDSflag==1
%     sv = [svGPS(svGPS(:,9)>=1,1:8); svBDS(svBDS(:,9)>=1,1:8)];
%     satnav = satnavSolve(sv, obj.rp);
%     obj.navFilter.run(obj.imu, [svGPS;svBDS]);
% end

%% 加权
% 获取卫星测量信息 & 获取通道信息 & 单独卫星导航解算
if obj.GPSflag==1
    satmeasGPS = obj.get_satmeasGPS; %卫星测量信息
    [~, ele] = aziele_xyz(satmeasGPS(:,1:3), obj.pos); %卫星高度角
    %---------------------------------------------------------------------%
    chN = obj.GPS.chN;
    quality = zeros(chN,1); %信号质量
    codeDisc = zeros(chN,1); %定位间隔内码鉴相器输出的平均值,m
    R_rho = zeros(chN,1); %伪距测量噪声方差,m^2
    R_rhodot = zeros(chN,1); %伪距率测量噪声方差,(m/s)^2
    for k=1:chN
        channel = obj.GPS.channels(k);
        if channel.state==3
            quality(k) = channel.quality;
            [co, ~] = channel.getDiscOutput;
            codeDisc(k) = sum(co)/length(co)*Lco;
            R_rho(k) = (sqrt(channel.codeVar.D/length(co))*Lco + 1.2*(1+16*(0.5-ele(k)/180)^3))^2;
            R_rhodot(k) = channel.carrVar.D*(6.15*Lca)^2;
        end
    end
    svGPS = [satmeasGPS, quality, R_rho, R_rhodot]; %带信号质量评价的卫星测量信息
    svGPS(:,7) = svGPS(:,7) - codeDisc; %本地码超前,伪距偏短,码鉴相器为负,修正是减
    %---------------------------------------------------------------------%
    sv = svGPS(svGPS(:,9)>=1,[1:8,10,11]); %选信号质量不为0的卫星
    satnavGPS = satnavSolveWeighted(sv, obj.rp);
end
if obj.BDSflag==1
    satmeasBDS = obj.get_satmeasBDS; %卫星测量信息
    [~, ele] = aziele_xyz(satmeasBDS(:,1:3), obj.pos); %卫星高度角
    %---------------------------------------------------------------------%
    chN = obj.BDS.chN;
    quality = zeros(chN,1); %信号质量
    codeDisc = zeros(chN,1); %定位间隔内码鉴相器输出的平均值,m
    R_rho = zeros(chN,1); %伪距测量噪声方差,m^2
    R_rhodot = zeros(chN,1); %伪距率测量噪声方差,(m/s)^2
    for k=1:chN
        channel = obj.BDS.channels(k);
        if channel.state==3
            quality(k) = channel.quality;
            [co, ~] = channel.getDiscOutput;
            codeDisc(k) = sum(co)/length(co)*Lco;
            R_rho(k) = (sqrt(channel.codeVar.D/length(co))*Lco + 1.2*(1+16*(0.5-ele(k)/180)^3))^2;
            R_rhodot(k) = channel.carrVar.D*(6.15*Lca)^2;
        end
    end
    svBDS = [satmeasBDS, quality, R_rho, R_rhodot]; %带信号质量评价的卫星测量信息
    svBDS(:,7) = svBDS(:,7) - codeDisc; %本地码超前,伪距偏短,码鉴相器为负,修正是减
    %---------------------------------------------------------------------%
    sv = svBDS(svBDS(:,9)>=1,[1:8,10,11]); %选信号质量不为0的卫星
    satnavBDS = satnavSolveWeighted(sv, obj.rp);
end

% 卫星导航解算 & 导航滤波
if obj.GPSflag==1 && obj.BDSflag==0
    satnav = satnavGPS;
    obj.navFilter.run(obj.imu, svGPS);
elseif obj.GPSflag==0 && obj.BDSflag==1
    satnav = satnavBDS;
    obj.navFilter.run(obj.imu, svBDS);
elseif obj.GPSflag==1 && obj.BDSflag==1
    sv = [svGPS(svGPS(:,9)>=1,[1:8,10,11]); svBDS(svBDS(:,9)>=1,[1:8,10,11])];
    satnav = satnavSolveWeighted(sv, obj.rp);
    obj.navFilter.run(obj.imu, [svGPS;svBDS]);
end

%%
% 计算加速度在ecef系下的表示
Cnb = quat2dcm(obj.navFilter.quat);
Cen = dcmecef2ned(obj.navFilter.pos(1), obj.navFilter.pos(2));
fb = obj.imu(4:6) - obj.navFilter.bias(4:6); %g
fn = (fb*Cnb + [0,0,1]) * obj.navFilter.g; %m/s^2
fe = fn*Cen;

% 通道修正
if obj.GPSflag==1
    satmeas = satmeasGPS;
    [rho0, rhodot0, rspu] = rho_rhodot_cal_ecef(satmeas(:,1:3), satmeas(:,4:6), ...
                            obj.navFilter.rp, obj.navFilter.vp); %理论相对距离和相对速度
    acclos0 = rspu*fe'; %计算接收机运动引起的相对加速度
    if obj.deepMode==1 %只修码相位
        for k=1:obj.GPS.chN
            channel = obj.GPS.channels(k);
            if channel.state==3
                channel.markCurrStorage;
                %----码相位修正
                dcodePhase = (rho0(k)-satmeas(k,7))/Lco; %码相位修正量
                channel.remCodePhase = channel.remCodePhase - dcodePhase;
                %----接收机运动引起的载波频率变化率
                channel.carrAccR = -acclos0(k)/Lca;
            end
        end
    elseif obj.deepMode==2 %修码相位和载波驱动频率
        for k=1:obj.GPS.chN
            channel = obj.GPS.channels(k);
            if channel.state==3
                channel.markCurrStorage;
                %----码相位修正
                dcodePhase = (rho0(k)-satmeas(k,7))/Lco; %码相位修正量
                channel.remCodePhase = channel.remCodePhase - dcodePhase;
                %----载波驱动频率修正
                dcarrFreq = (rhodot0(k)-satmeas(k,8))/Lca; %相对估计频率的修正量
%                 dcarrFreq = dcarrFreq + (channel.carrNco-channel.carrFreq); %相对驱动频率的修正量
%                 channel.carrNco = channel.carrNco - dcarrFreq;
                channel.carrNco = channel.carrFreq - dcarrFreq; %上两行的简写
                %----接收机运动引起的载波频率变化率
                channel.carrAccR = -acclos0(k)/Lca;
            end
        end
    end
end
if obj.BDSflag==1
    satmeas = satmeasBDS;
    [rho0, rhodot0, rspu] = rho_rhodot_cal_ecef(satmeas(:,1:3), satmeas(:,4:6), ...
                            obj.navFilter.rp, obj.navFilter.vp); %理论相对距离和相对速度
    acclos0 = rspu*fe'; %计算接收机运动引起的相对加速度
    if obj.deepMode==1 %只修码相位
        for k=1:obj.BDS.chN
            channel = obj.BDS.channels(k);
            if channel.state==3
                channel.markCurrStorage;
                %----码相位修正
                dcodePhase = (rho0(k)-satmeas(k,7))/Lco*2; %码相位修正量(子载波)
                channel.remCodePhase = channel.remCodePhase - dcodePhase;
                %----接收机运动引起的载波频率变化率
                channel.carrAccR = -acclos0(k)/Lca;
            end
        end
    elseif obj.deepMode==2 %修码相位和载波驱动频率
        for k=1:obj.BDS.chN
            channel = obj.BDS.channels(k);
            if channel.state==3
                channel.markCurrStorage;
                %----码相位修正
                dcodePhase = (rho0(k)-satmeas(k,7))/Lco*2; %码相位修正量(子载波)
                channel.remCodePhase = channel.remCodePhase - dcodePhase;
                %----载波驱动频率修正
                dcarrFreq = (rhodot0(k)-satmeas(k,8))/Lca; %相对估计频率的修正量
%                 dcarrFreq = dcarrFreq + (channel.carrNco-channel.carrFreq); %相对驱动频率的修正量
%                 channel.carrNco = channel.carrNco - dcarrFreq;
                channel.carrNco = channel.carrFreq - dcarrFreq; %上两行的简写
                %----接收机运动引起的载波频率变化率
                channel.carrAccR = -acclos0(k)/Lca;
            end
        end
    end
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
obj.storage.satnav(m,:) = satnav([1,2,3,7,8,9,13,14]);
if obj.GPSflag==1
    obj.storage.satnavGPS(m,:) = satnavGPS([1,2,3,7,8,9,13,14]);
    obj.storage.qualGPS(m,:) = svGPS(:,9);
end
if obj.BDSflag==1
    obj.storage.satnavBDS(m,:) = satnavBDS([1,2,3,7,8,9,13,14]);
    obj.storage.qualBDS(m,:) = svBDS(:,9);
end
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
obj.storage.motion(m) = obj.navFilter.motion.state;

% 更新下次定位时间
obj.tp(1) = NaN;

end