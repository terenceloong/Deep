function pos_normal(obj)
% 正常模式定位

% 获取卫星测量信息
satmeas = obj.get_satmeas;

% 卫星导航解算
sv = satmeas(~isnan(satmeas(:,1)),:); %选星
satnav = satnavSolve(sv, obj.rp);
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
obj.storage.satmeas(:,:,m) = satmeas;
obj.storage.satnav(m,:) = satnav([1,2,3,7,8,9,13,14]);
obj.storage.pos(m,:) = obj.pos;
obj.storage.vel(m,:) = obj.vel;

% 更新下次定位时间
obj.tp = timeCarry(obj.tp + [0,obj.dtpos,0]);

end