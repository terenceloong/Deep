function pos_deep(obj)
% 深组合定位

% 波长
Lca = 299792458/1575.42e6; %载波长,m
Lco = 299792458/1.023e6; %码长,m

% 获取卫星测量信息
satmeas = obj.get_satmeas;
[~, ele] = aziele_xyz(satmeas(:,1:3), obj.pos); %卫星高度角

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
        codeDisc(k) = sum(co)/length(co)*Lco;
        R_rho(k) = (sqrt(channel.codeVar.D/length(co))*Lco + 1.2*(1+16*(0.5-ele(k)/180)^3))^2;
        R_rhodot(k) = channel.carrVar.D*(6.15*Lca)^2;
    end
end
sv = [satmeas, quality, R_rho, R_rhodot]; %带信号质量评价的卫星测量信息
sv(:,7) = sv(:,7) - codeDisc; %用码鉴相器输出修正伪距,本地码超前,伪距偏短,码鉴相器为负,修正是减

% 卫星导航解算
% sv1 = sv(sv(:,9)>=1,1:8); %选信号质量不为0的卫星
% satnav = satnavSolve(sv1, obj.rp);
sv1 = sv(sv(:,9)>=1,[1:8,10,11]); %选信号质量不为0的卫星
satnav = satnavSolveWeighted(sv1, obj.rp);

% 导航滤波
obj.navFilter.run(obj.imu, sv);

% 计算ecef系下加速度
Cnb = quat2dcm(obj.navFilter.quat);
Cen = dcmecef2ned(obj.navFilter.pos(1), obj.navFilter.pos(2));
fb = (obj.imu(4:6) - obj.navFilter.bias(4:6)) * obj.navFilter.g; %惯导加速度,m/s^2
wb = (obj.imu(1:3) - obj.navFilter.bias(1:3)) /180*pi; %角速度,rad/s
wdot = obj.navFilter.wdot /180*pi; %角加速度,rad/s/s
arm = obj.navFilter.arm; %体系下杆臂矢量
fbt = cross(wdot,arm); %切向加速度,m/s^2
fbn = cross(wb,cross(wb,arm)); %法向加速度,m/s^2
fn = (fb+fbt+fbn)*Cnb + [0,0,obj.navFilter.g]; %地理系下加速度
fe = fn*Cen; %ecef系下加速度

% 计算ecef系下杆臂位置速度
r_arm = arm*Cnb*Cen;
v_arm = cross(wb,arm)*Cnb*Cen;

% 惯导位置速度做杆臂修正后得到天线位置速度
obj.rp = obj.navFilter.rp + r_arm;
obj.vp = obj.navFilter.vp + v_arm;
obj.att = obj.navFilter.att;
obj.pos = ecef2lla(obj.rp);
obj.vel = obj.vp*Cen';

[rho0, rhodot0, rspu] = rho_rhodot_cal_ecef(satmeas(:,1:3), satmeas(:,4:6), ...
                        obj.rp, obj.vp); %理论相对距离和相对速度
acclos0 = rspu*fe'; %计算接收机运动引起的相对加速度

% 通道修正 (伪距短,码相位超前; 伪距率小,载波频率快)
if obj.deepMode==1 %只修码相位
    for k=1:chN
        channel = obj.channels(k);
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
    for k=1:chN
        channel = obj.channels(k);
        if channel.state==3
            channel.markCurrStorage;
            %----码相位修正
            dcodePhase = (rho0(k)-satmeas(k,7))/Lco; %码相位修正量
            channel.remCodePhase = channel.remCodePhase - dcodePhase;
            %----载波驱动频率修正
            dcarrFreq = (rhodot0(k)-satmeas(k,8))/Lca; %相对估计频率的修正量
%             dcarrFreq = dcarrFreq + (channel.carrNco-channel.carrFreq); %相对驱动频率的修正量
%             channel.carrNco = channel.carrNco - dcarrFreq;
            channel.carrNco = channel.carrFreq - dcarrFreq; %上两行的简写
            %----接收机运动引起的载波频率变化率
            channel.carrAccR = -acclos0(k)/Lca;
        end
    end
end

% 新跟踪的通道切换深组合跟踪环路
obj.channel_deep;

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
obj.storage.P(m,1:size(P,1)) = sqrt(diag(P));
Cnb = quat2dcm(obj.navFilter.quat);
P_angle = var_phi2angle(P(1:3,1:3), Cnb);
obj.storage.P(m,1:3) = sqrt(diag(P_angle));
obj.storage.quality(m,:) = quality;

% 更新下次定位时间
obj.tp(1) = NaN;
    
end