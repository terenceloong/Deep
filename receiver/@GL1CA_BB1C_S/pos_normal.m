function pos_normal(obj)
% 正常定位

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
end

% 卫星导航解算
if obj.GPSflag==1 && obj.BDSflag==0
    satnav = satnavGPS;
elseif obj.GPSflag==0 && obj.BDSflag==1
    satnav = satnavBDS;
elseif obj.GPSflag==1 && obj.BDSflag==1
    sv = [svGPS; svBDS];
    svIndex = [svIndexGPS; svIndexBDS];
    satnav = satnavSolveWeighted(sv(svIndex,:), obj.rp);
end
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
m = obj.ns;
obj.storage.ta(m) = obj.tp * [1;1e-3;1e-6]; %定位时间,s
obj.storage.df(m) = obj.deltaFreq;
obj.storage.satnav(m,:) = satnav([1,2,3,7,8,9,13,14]);
if obj.GPSflag==1
    obj.storage.satnavGPS(m,:) = satnavGPS([1,2,3,7,8,9,13,14]);
    obj.storage.svselGPS(m,:) = svIndexGPS + svIndexGPS;
end
if obj.BDSflag==1
    obj.storage.satnavBDS(m,:) = satnavBDS([1,2,3,7,8,9,13,14]);
    obj.storage.svselBDS(m,:) = svIndexBDS + svIndexBDS;
end
obj.storage.pos(m,:) = obj.pos;
obj.storage.vel(m,:) = obj.vel;

% 更新下次定位时间
obj.tp = timeCarry(obj.tp + [0,obj.dtpos,0]);

end