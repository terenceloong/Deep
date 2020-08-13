function pos_normal(obj)
% 正常定位

%% 不加权
% % 获取卫星测量信息 & 单独卫星导航解算
% if obj.GPSflag==1
%     satmeasGPS = obj.get_satmeasGPS;
%     sv = satmeasGPS(~isnan(satmeasGPS(:,1)),:); %选星
%     satnavGPS = satnavSolve(sv, obj.rp);
% end
% if obj.BDSflag==1
%     satmeasBDS = obj.get_satmeasBDS;
%     sv = satmeasBDS(~isnan(satmeasBDS(:,1)),:); %选星
%     satnavBDS = satnavSolve(sv, obj.rp);
% end
% 
% % 卫星导航解算
% if obj.GPSflag==1 && obj.BDSflag==0
%     satnav = satnavGPS;
% elseif obj.GPSflag==0 && obj.BDSflag==1
%     satnav = satnavBDS;
% elseif obj.GPSflag==1 && obj.BDSflag==1
%     satmeas = [satmeasGPS; satmeasBDS];
%     sv = satmeas(~isnan(satmeas(:,1)),:); %选星
%     satnav = satnavSolve(sv, obj.rp);
% end
% dtr = satnav(13); %接收机钟差,s
% dtv = satnav(14); %接收机钟频差,s/s

%% 加权
% 波长
Lca = 299792458/1575.42e6; %载波长,m
Lco = 299792458/1.023e6; %码长,m

% 获取卫星测量信息 & 获取通道信息 & 单独卫星导航解算
if obj.GPSflag==1
    satmeasGPS = obj.get_satmeasGPS; %卫星测量信息
    [~, ele] = aziele_xyz(satmeasGPS(:,1:3), obj.pos); %卫星高度角
    %---------------------------------------------------------------------%
    chN = obj.GPS.chN;
    quality = zeros(chN,1); %信号质量
    R_rho = zeros(chN,1); %伪距测量噪声方差,m^2
    R_rhodot = zeros(chN,1); %伪距率测量噪声方差,(m/s)^2
    for k=1:chN
        channel = obj.GPS.channels(k);
        if channel.state==2
            quality(k) = channel.quality;
            R_rho(k) = (sqrt(channel.codeVar.D)*0.12*Lco + 1.2*(1+16*(0.5-ele(k)/180)^3))^2;
            R_rhodot(k) = channel.carrVar.D*(6.15*Lca)^2;
        end
    end
    svGPS = [satmeasGPS, quality, R_rho, R_rhodot]; %带信号质量评价的卫星测量信息
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
    R_rho = zeros(chN,1); %伪距测量噪声方差,m^2
    R_rhodot = zeros(chN,1); %伪距率测量噪声方差,(m/s)^2
    for k=1:chN
        channel = obj.BDS.channels(k);
        if channel.state==2
            quality(k) = channel.quality;
            R_rho(k) = (sqrt(channel.codeVar.D)*0.12*Lco + 1.2*(1+16*(0.5-ele(k)/180)^3))^2;
            R_rhodot(k) = channel.carrVar.D*(6.15*Lca)^2;
        end
    end
    svBDS = [satmeasBDS, quality, R_rho, R_rhodot]; %带信号质量评价的卫星测量信息
    %---------------------------------------------------------------------%
    sv = svBDS(svBDS(:,9)>=1,[1:8,10,11]); %选信号质量不为0的卫星
    satnavBDS = satnavSolveWeighted(sv, obj.rp);
end

% 卫星导航解算
if obj.GPSflag==1 && obj.BDSflag==0
    satnav = satnavGPS;
elseif obj.GPSflag==0 && obj.BDSflag==1
    satnav = satnavBDS;
elseif obj.GPSflag==1 && obj.BDSflag==1
    sv = [svGPS(svGPS(:,9)>=1,[1:8,10,11]); svBDS(svBDS(:,9)>=1,[1:8,10,11])];
    satnav = satnavSolveWeighted(sv, obj.rp);
end
dtr = satnav(13); %接收机钟差,s
dtv = satnav(14); %接收机钟频差,s/s

%%
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
    obj.storage.qualGPS(m,:) = svGPS(:,9);
end
if obj.BDSflag==1
    obj.storage.satnavBDS(m,:) = satnavBDS([1,2,3,7,8,9,13,14]);
    obj.storage.qualBDS(m,:) = svBDS(:,9);
end
obj.storage.pos(m,:) = obj.pos;
obj.storage.vel(m,:) = obj.vel;

% 更新下次定位时间
obj.tp = timeCarry(obj.tp + [0,obj.dtpos,0]);

end