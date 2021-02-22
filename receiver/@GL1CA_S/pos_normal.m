function pos_normal(obj)
% 正常定位

% 获取卫星测量信息
satmeas = obj.get_satmeas;

% 卫星导航解算(不加权)
% svIndex = ~isnan(satmeas(:,1)); %选星
% satnav = satnavSolve(satmeas(svIndex,:), obj.rp);
% dtr = satnav(13); %接收机钟差,s
% dtv = satnav(14); %接收机钟频差,s/s

% 高度角引起的误差
[~, ele] = aziele_xyz(satmeas(:,1:3), obj.pos); %卫星高度角
eleError = 5*(1-1./(1+exp(-((ele-30)/5))));

% 卫星导航解算(加权)
chN = obj.chN;
CN0 = zeros(chN,1); %载噪比
R_rho = zeros(chN,1); %伪距测量噪声方差,m^2
R_rhodot = zeros(chN,1); %伪距率测量噪声方差,(m/s)^2
for k=1:chN
    channel = obj.channels(k);
    if channel.state==2
        CN0(k) = channel.CN0;
        R_rho(k) = (sqrt(channel.varValue(1))+eleError(k))^2;
        R_rhodot(k) = channel.varValue(2);
    end
end
sv = [satmeas, R_rho, R_rhodot];
svIndex = CN0>=37; %选星
satnav = satnavSolveWeighted(sv(svIndex,:), obj.rp);
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
    obj.deltaFreq = obj.deltaFreq + 10*dtv*T;
    obj.ta = obj.ta - sec2smu(10*dtr*T);
end

% 数据存储
obj.ns = obj.ns+1; %指向当前存储行
m = obj.ns;
obj.storage.ta(m) = obj.tp * [1;1e-3;1e-6]; %定位时间,s
obj.storage.df(m) = obj.deltaFreq;
obj.storage.satmeas(:,:,m) = sv; %satmeas;
obj.storage.satnav(m,:) = satnav([1,2,3,7,8,9,13,14]);
obj.storage.svsel(m,:) = svIndex;
obj.storage.pos(m,:) = obj.pos;
obj.storage.vel(m,:) = obj.vel;

% 更新下次定位时间
obj.tp = timeCarry(obj.tp + [0,obj.dtpos,0]);

end