function [rsvs, corr] = rsvs_emit(ephe, te0, rp, iono, lla)
% 计算卫星在信号发射时刻的位置速度,计算伪距伪距率校正量
% ephe:星历,21参数(5+16)
% te0:信号名义发射时间,[s,ms,us]
% rp:接收机ecef位置(大致),用于计算Sagnac校正
% iono:电离层校正参数,可以没有
% lla:接收机纬经高,与rp对应,deg,与iono同时出现
% rsvs:卫星ecef位置速度,[x,y,z,vx,vy,vz]
% corr:伪距伪距率校正量,结构体

if length(ephe)~=21
    error('Ephemeris error!')
end

% 地球参数
w = 7.2921151467e-5;
c = 299792458;

% 提取星历参数
toc = ephe(1);
af0 = ephe(2);
af1 = ephe(3);
af2 = ephe(4);
TGD = ephe(5);

% 计算卫星钟差
dt = te0(1) - toc + te0(2)/1e3 + te0(3)/1e6; %s
dt = roundWeek(dt);
dtsv = af0 + af1*dt + af2*dt^2; %卫星钟差,s
dfsv = af1 + 2*af2*dt; %卫星钟频差,s/s

% 信号实际发射时间(钟快了往下减)
te = te0(3)/1e6 - dtsv + te0(2)/1e3 + te0(1); %s

% 计算卫星位置速度
[rsvs, dtrel] = LNAV.rsvs_ephe(ephe(6:end), te);

% 计算Saganc效应校正项
rs = rsvs(1:3);
dtsagnac = (rs(1)*rp(2)-rs(2)*rp(1))*w/c^2;

% 计算相对论效应引起的卫星钟频差
% 最大6ps/s,跟卫星钟频差一个量级
% <Springer Handbook of Global Navigation Satellite Systems>564页(19.16)
dfr = 0.00887005737336 * (1/ephe(7)^2 - 1/norm(rs)); %2*miu/c^2=0.00887005737336

% 计算电离层延迟
if exist('iono','var') && ~isnan(iono(1)) %存在电离层参数
    % 计算卫星方位角高度角
    Cen = dcmecef2ned(lla(1), lla(2));
    rps = rs-rp; %接收机指向卫星的位置矢量,ecef
    rpsu = rps/norm(rps); %单位矢量
    rpsu_n = Cen*rpsu'; %转到地理系下
    azi = atan2d(rpsu_n(2),rpsu_n(1)); %方位角,deg
    ele = asind(-rpsu_n(3)); %高度角,deg
    % 使用Klobuchar模型计算电离层延迟
    dtiono = Klobuchar(iono, azi, ele, lla(1), lla(2), te);
else
    dtiono = 0;
end

% 输出校正量
corr.dtsv = dtsv; %卫星钟差,s
corr.dtrel = dtrel; %相对论钟差,s
corr.dtsagnac = dtsagnac; %Saganc效应延迟,s
corr.TGD = TGD; %群延迟,s
corr.dtiono = dtiono; %电离层延迟,s
corr.dfsv = dfsv; %卫星钟频差,s/s
corr.dfr = dfr; %相对论钟频差,s/s

end