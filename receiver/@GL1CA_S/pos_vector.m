function pos_vector(obj)
% 纯矢量跟踪定位

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
sv = [satmeas, R_rho, R_rhodot];
sv(:,7) = sv(:,7) - codeDisc; %用码鉴相器输出修正伪距,本地码超前,伪距偏短,码鉴相器为负,修正是减

% 卫星导航解算
svIndex = CN0>=37; %选星
satnav = satnavSolveWeighted(sv(svIndex,:), obj.rp);

% 导航滤波
indexP = CN0>=33; %使用伪距的索引
indexV = CN0>=37; %使用伪距率的索引(更改阈值时,载波跟踪处的阈值也要改)
[innP, innV] = obj.navFilter.run(sv, indexP, indexV);

% 计算ecef系下加速度
Cen = dcmecef2ned(obj.navFilter.pos(1), obj.navFilter.pos(2));
fn = obj.navFilter.acc; %地理系下加速度
fe = fn*Cen; %ecef系下加速度

% 更新接收机位置速度
obj.pos = obj.navFilter.pos;
obj.vel = obj.navFilter.vel;
obj.rp = obj.navFilter.rp;
obj.vp = obj.navFilter.vp;
obj.geogInfo = geogInfo_cal(obj.pos, obj.vel);

[rho0, rhodot0, rspu] = rho_rhodot_cal_ecef(satmeas(:,1:3), satmeas(:,4:6), ...
                        obj.rp, obj.vp); %理论相对距离和相对速度
acclos0 = rspu*fe'; %计算接收机运动引起的相对加速度

% 通道修正
Cdf = 1 + obj.deltaFreq; %跟踪频率到真实频率的系数
dtr_code = obj.navFilter.dtr * 1.023e6; %钟差对应的码相位
dtv_carr = obj.navFilter.dtv * 1575.42e6; %钟频差对应的载波频率
if obj.vectorMode==3 %修码相位和载波驱动频率
    for k=1:chN
        channel = obj.channels(k);
        if channel.state==3
            %----码相位修正
            dcodePhase = (rho0(k)-satmeas(k,7))/Lco + dtr_code; %码相位修正量
            channel.remCodePhase = channel.remCodePhase - dcodePhase;
            %----载波驱动频率修正
            dcarrFreq = (rhodot0(k)-satmeas(k,8))/Lca + dtv_carr; %相对估计频率的修正量
            channel.carrNco = channel.carrFreq - dcarrFreq/Cdf;
            %----接收机运动引起的载波频率变化率
            channel.carrAccE = -acclos0(k)/Lca / Cdf; %设置载波加速度估计值,不是载波加速度驱动值carrAccR
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
% obj.navFilter.dtr = 0;

% 数据存储
obj.ns = obj.ns+1; %指向当前存储行
m = obj.ns;
obj.storage.ta(m) = obj.tp * [1;1e-3;1e-6]; %定位时间,s
obj.storage.df(m) = obj.deltaFreq;
obj.storage.satmeas(:,:,m) = sv;
obj.storage.satnav(m,:) = satnav([1,2,3,7,8,9,13,14]);
obj.storage.svsel(m,:) = indexP + indexV;
obj.storage.pos(m,:) = obj.pos;
obj.storage.vel(m,:) = obj.vel;
P = obj.navFilter.P;
obj.storage.P(m,1:size(P,1)) = sqrt(diag(P));
obj.storage.others(m,8) = obj.navFilter.dtr;
obj.storage.others(m,9) = obj.navFilter.dtv;
obj.storage.others(m,10:12) = fn;
obj.storage.innP(m,:) = innP;
obj.storage.innV(m,:) = innV;
c = 299792458;
obj.storage.resP(m,:) = rho0 - sv(:,7) + obj.navFilter.dtr*c;
obj.storage.resV(m,:) = rhodot0 - sv(:,8) + obj.navFilter.dtv*c;

% 更新下次定位时间
obj.tp = timeCarry(obj.tp + [0,obj.dtpos,0]);

end