function pos_normal(obj)
% 正常定位

% 获取卫星测量信息
[satpv, satmeas] = obj.get_satmeas;

% 高度角引起的误差
[~, ele] = aziele_xyz(satpv(:,1:3), obj.pos); %卫星高度角
eleError = 5*(1-1./(1+exp(-((ele-30)/5)))); %S函数(Sigmoid函数) 1/(1+e^-x)

% 卫星导航解算(加权)
anN = obj.anN;
chN = obj.chN;
CN0 = zeros(chN,anN); %载噪比(每列是一个天线)
R_rho = zeros(chN,anN); %伪距测量噪声方差,m^2
R_rhodot = zeros(chN,anN); %伪距率测量噪声方差,(m/s)^2
R_phase = zeros(chN,anN); %载波相位测量噪声方差,(circ)^2
for m=1:anN
    for k=1:chN
        channel = obj.channels(k,m);
        if channel.state==2
            CN0(k,m) = channel.CN0;
            R_rho(k,m) = (sqrt(channel.varValue(1))+eleError(k))^2;
            R_rhodot(k,m) = channel.varValue(2);
            R_phase(k,m) = channel.varValue(4);
        end
    end
end
svIndex = CN0>=obj.CN0Thr.strong; %选星(所有天线)
sv = [satpv, satmeas{1}(:,1:2), R_rho(:,1), R_rhodot(:,1)]; %天线1
satnav = satnavSolveWeighted(sv(svIndex(:,1),:), obj.rp);
dtr = satnav(13); %接收机钟差,s
dtv = satnav(14); %接收机钟频差,s/s

% 更新接收机位置速度
if ~isnan(satnav(1))
    obj.pos = satnav(1:3);
    obj.rp  = satnav(4:6);
    obj.vel = satnav(7:9);
    obj.vp  = satnav(10:12);
    obj.geogInfo = geogInfo_cal(obj.pos, obj.vel);
end

% 接收机时钟修正
if ~isnan(dtr)
    T = obj.dtpos/1000; %定位时间间隔,s
    tv_corr = 10*dtv*T; %钟频差修正量
    tr_corr = 10*dtr*T; %钟差修正量
    obj.deltaFreq = obj.deltaFreq + tv_corr;
    obj.ta = obj.ta - sec2smu(tr_corr);
    obj.clockError = obj.clockError + tr_corr; %累计钟差修正量
end

% 数据存储
obj.ns = obj.ns+1; %指向当前存储行
k = obj.ns;
obj.storage.ta(k) = obj.tp * [1;1e-3;1e-6]; %定位时间,s
obj.storage.df(k) = obj.deltaFreq;
obj.storage.satpv(:,:,k) = satpv;
for m=1:anN
    obj.storage.satmeas(:,1:3,k,m) = satmeas{m};
    obj.storage.satmeas(:,4,k,m) = R_rho(:,m);
    obj.storage.satmeas(:,5,k,m) = R_rhodot(:,m);
    obj.storage.satmeas(:,6,k,m) = R_phase(:,m);
    obj.storage.satmeas(:,7,k,m) = CN0(:,m);
    obj.storage.svsel(:,1,k,m) = svIndex(:,m) + svIndex(:,m);
end
obj.storage.satnav(k,:) = satnav([1,2,3,7,8,9,13,14]);
obj.storage.pos(k,:) = obj.pos;
obj.storage.vel(k,:) = obj.vel;

% 更新下次定位时间
obj.tp = timeCarry(obj.tp + [0,obj.dtpos,0]);

end