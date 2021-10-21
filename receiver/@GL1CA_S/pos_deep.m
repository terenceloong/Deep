function pos_deep(obj)
% 深组合定位

% 波长
Lca = 0.190293672798365; %载波波长,m (299792458/1575.42e6)
Lco = 293.0522561094819; %码长,m (299792458/1.023e6)

% 获取卫星测量信息
satmeas = obj.get_satmeas;

% 高度角引起的误差
[~, ele] = aziele_xyz(satmeas(:,1:3), obj.pos); %卫星高度角
eleError = 5*(1-1./(1+exp(-((ele-30)/5))));

% 获取通道信息
chN = obj.chN;
CN0 = zeros(chN,1); %载噪比
codeDisc = zeros(chN,1); %定位间隔内码鉴相器输出的平均值,m
R_rho = zeros(chN,1); %伪距测量噪声方差,m^2
R_rhodot = zeros(chN,1); %伪距率测量噪声方差,(m/s)^2
for k=1:chN
    channel = obj.channels(k);
    if channel.state==3
        n = channel.codeDiscBuffPtr; %码鉴相器缓存内数据个数
        if n>0 %定位间隔内码鉴相器有输出
            CN0(k) = channel.CN0;
            codeDisc(k) = sum(channel.codeDiscBuff(1:n))/n * Lco;
            R_rho(k) = (sqrt(channel.varValue(3)/n)+eleError(k))^2;
            R_rhodot(k) = channel.varValue(2);
            channel.codeDiscBuffPtr = 0;
        end
    end
end
sv = [satmeas(:,1:8), R_rho, R_rhodot];
sv(:,7) = sv(:,7) - codeDisc; %用码鉴相器输出修正伪距,本地码超前,伪距偏短,码鉴相器为负,修正是减

% 卫星导航解算
svIndex = CN0>=37; %选星
satnav = satnavSolveWeighted(sv(svIndex,:), obj.rp);

% 导航滤波
indexP = CN0>=33; %使用伪距的索引
indexV = CN0>=37; %使用伪距率的索引(更改阈值时,载波跟踪处的阈值也要改)
obj.navFilter.run(obj.imu, sv, indexP, indexV);

% 计算ecef系下加速度
Cnb = quat2dcm(obj.navFilter.quat);
Cen = dcmecef2ned(obj.navFilter.pos(1), obj.navFilter.pos(2));
fb = obj.imu(4:6) - obj.navFilter.bias(4:6); %惯导加速度,m/s^2
wb = obj.imu(1:3) - obj.navFilter.bias(1:3); %角速度,rad/s
wdot = obj.navFilter.wdot; %角加速度,rad/s^2
arm = obj.navFilter.arm; %体系下杆臂矢量
fbt = cross(wdot,arm); %切向加速度,m/s^2
fbn = cross(wb,cross(wb,arm)); %法向加速度,m/s^2
fh = cross(2*obj.geogInfo.wien+obj.geogInfo.wenn, obj.vel); %有害加速度
fn = (fb+fbt+fbn)*Cnb + [0,0,obj.geogInfo.g] - fh; %地理系下加速度(刨除有害加速度)
% fe = fn*Cen; %ecef系下加速度
%----外推半步
if isnan(obj.fn0)
    fn1 = fn;
else
    fn1 = (3*fn-obj.fn0)/2;
end
obj.fn0 = fn;
fe = fn1*Cen; %ecef系下加速度

% 计算ecef系下杆臂位置速度
r_arm = arm*Cnb*Cen;
v_arm = cross(wb,arm)*Cnb*Cen;

% 惯导位置速度做杆臂修正后得到天线位置速度
obj.rp = obj.navFilter.rp + r_arm;
obj.vp = obj.navFilter.vp + v_arm;
obj.att = obj.navFilter.att;
obj.pos = ecef2lla(obj.rp);
obj.vel = obj.vp*Cen';
obj.geogInfo = geogInfo_cal(obj.pos, obj.vel);

[rho0, rhodot0, rspu] = rho_rhodot_cal_ecef(satmeas(:,1:3), satmeas(:,4:6), ...
                        obj.rp, obj.vp); %理论相对距离和相对速度
acclos0 = rspu*fe'; %计算接收机运动引起的相对加速度

% 通道修正 (伪距短,码相位超前; 伪距率小,载波频率快)
Cdf = 1 + obj.deltaFreq; %跟踪频率到真实频率的系数
dtr_code = obj.navFilter.dtr * 1.023e6; %钟差对应的码相位
dtv_carr = obj.navFilter.dtv * 1575.42e6; %钟频差对应的载波频率
if obj.vectorMode==1 %只修码相位
    for k=1:chN
        channel = obj.channels(k);
        if channel.state==3
            %----码相位修正(satmeas中的伪距是带钟差的,需要补回来,才能得到修正量)
            dcodePhase = (rho0(k)-satmeas(k,7))/Lco + dtr_code; %码相位修正量
            channel.remCodePhase = channel.remCodePhase - dcodePhase;
            %----接收机运动引起的载波频率变化率
            channel.carrAccR = -acclos0(k)/Lca / Cdf;
        end
    end
elseif obj.vectorMode==2 %修码相位和载波驱动频率
    for k=1:chN
        channel = obj.channels(k);
        if channel.state==3
            %----码相位修正(satmeas中的伪距是带钟差的,需要补回来,才能得到修正量)
            dcodePhase = (rho0(k)-satmeas(k,7))/Lco + dtr_code; %码相位修正量
            channel.remCodePhase = channel.remCodePhase - dcodePhase;
            %----载波驱动频率修正(satmeas中的伪距率是带钟频差的,需要补回来,才能得到修正量)
            dcarrFreq = (rhodot0(k)-satmeas(k,8))/Lca + dtv_carr; %相对估计频率的修正量
            channel.carrNco = channel.carrFreq - dcarrFreq/Cdf;
            %----接收机运动引起的载波频率变化率
            channel.carrAccR = -acclos0(k)/Lca / Cdf;
        end
    end
else
    error('vectorMode error!')
end

% 新跟踪的通道切换矢量跟踪环路
obj.channel_vector;

% 接收机时钟修正
% obj.deltaFreq = obj.deltaFreq + obj.navFilter.dtv;
% obj.navFilter.dtv = 0;
% obj.ta = obj.ta - sec2smu(obj.navFilter.dtr);
% obj.clockError = obj.clockError + obj.navFilter.dtr;
% obj.navFilter.dtr = 0;

% 数据存储
obj.ns = obj.ns+1; %指向当前存储行
m = obj.ns;
obj.storage.ta(m) = obj.tp * [1;1e-3;1e-6]; %定位时间,s
obj.storage.df(m) = obj.deltaFreq;
obj.storage.satmeas(:,1:10,m) = sv;
obj.storage.satmeas(:,11,m) = satmeas(:,9); %载波相位
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
obj.storage.others(m,1:3) = obj.navFilter.arm;
obj.storage.others(m,4:6) = obj.navFilter.wdot;
% obj.storage.others(m,7) = obj.navFilter.delay;
obj.storage.others(m,8) = obj.navFilter.dtr;
obj.storage.others(m,9) = obj.navFilter.dtv;
obj.storage.others(m,10:12) = fn;

% 更新下次定位时间
obj.tp(1) = NaN;

end