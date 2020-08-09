function pos_normal(obj)
% 正常定位

% 获取卫星测量信息 & 单独卫星导航解算
if obj.GPSflag==1
    satmeasGPS = obj.get_satmeasGPS;
    sv = satmeasGPS(~isnan(satmeasGPS(:,1)),:); %选星
    satnavGPS = satnavSolve(sv, obj.rp);
end
if obj.BDSflag==1
    satmeasBDS = obj.get_satmeasBDS;
    sv = satmeasBDS(~isnan(satmeasBDS(:,1)),:); %选星
    satnavBDS = satnavSolve(sv, obj.rp);
end

% 卫星导航解算
if obj.GPSflag==1 && obj.BDSflag==0
    satnav = satnavGPS;
elseif obj.GPSflag==0 && obj.BDSflag==1
    satnav = satnavBDS;
elseif obj.GPSflag==1 && obj.BDSflag==1
    satmeas = [satmeasGPS; satmeasBDS];
    sv = satmeas(~isnan(satmeas(:,1)),:); %选星
    satnav = satnavSolve(sv, obj.rp);
end
dtr = satnav(13); %接收机钟差,s
dtv = satnav(14); %接收机钟频差,s/s

% 更新接收机位置速度
if ~isnan(satnav(1))
    obj.pos = satnav(1:3);
    obj.rp  = satnav(4:6);
    obj.vel = satnav(7:9);
    obj.vp  = satnav(10:12);
end

% 接收机时钟修正
if ~isnan(dtr)
    T = obj.dtpos/1000; %定位时间间隔,s
    obj.deltaFreq = obj.deltaFreq + 10*dtv*T;
    obj.ta = obj.ta - sec2smu(10*dtr*T);
end

% 数据存储
obj.ns = obj.ns+1; %指向当前存储行
m = obj.ns;
obj.storage.ta(m) = obj.tp * [1;1e-3;1e-6]; %定位时间,s
obj.storage.df(m) = obj.deltaFreq;
obj.storage.satnav(m,:) = satnav([1,2,3,7,8,9,13,14]);
if obj.GPSflag==1
    obj.storage.satnavGPS(m,:) = satnavGPS([1,2,3,7,8,9,13,14]);
end
if obj.BDSflag==1
    obj.storage.satnavBDS(m,:) = satnavBDS([1,2,3,7,8,9,13,14]);
end
obj.storage.pos(m,:) = obj.pos;
obj.storage.vel(m,:) = obj.vel;

% 更新下次定位时间
obj.tp = timeCarry(obj.tp + [0,obj.dtpos,0]);

end