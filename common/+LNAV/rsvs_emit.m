function [rsvs, corr] = rsvs_emit(ephe, te0, rp, vp, iono, lla)
% 计算卫星在信号发射时刻的位置速度,计算伪距伪距率校正量
% ephe:21参数星历(5+16)
% te0:信号名义发射时间,[s,ms,us]
% rp:接收机ecef位置(大致),用于计算Sagnac校正
% vp:接收机ecef速度,用于计算Sagnac频率差
% iono:电离层校正参数,NaN表示无效
% lla:接收机纬经高,与rp对应,deg
% rsvs:卫星ecef位置速度,[x,y,z,vx,vy,vz]
% corr:伪距伪距率校正量,结构体

% 检查星历参数个数
if length(ephe)~=21
    error('Ephemeris error!')
end

% 提取星历参数
toc = ephe(1);
af0 = ephe(2);
af1 = ephe(3);
af2 = ephe(4);
TGD = ephe(5);
a = ephe(7)^2; %半长轴
ephe0 = ephe(6:end); %16参数星历,用于计算卫星位置速度

% 计算卫星钟差
dt = te0(1) - toc + te0(2)/1e3 + te0(3)/1e6; %s
dt = mod(dt+302400,604800)-302400; %限制在±302400
dtsv = af0 + af1*dt + af2*dt^2; %卫星钟差,s
dfsv = af1 + 2*af2*dt; %卫星钟频差,s/s

% 信号实际发射时间(钟快了往下减)
te = te0(3)/1e6 - dtsv + te0(2)/1e3 + te0(1); %s

% 计算卫星位置速度
[rsvs, dtrel] = LNAV.rsvs_ephe(ephe0, te);

% 计算Saganc效应校正项
w_c2 = 8.113572326725195e-22; %w/c^2, w=7.2921151467e-5, c=299792458
rs = rsvs(1:3);
dtsagnac = (rs(1)*rp(2)-rs(2)*rp(1)) * w_c2;
vs = rsvs(4:6);
dfsagnac = (vs(1)*rp(2)-vs(2)*rp(1)+rs(1)*vp(2)-rs(2)*vp(1)) * w_c2;

% 计算相对论效应引起的卫星钟频差
% 最大6ps/s,跟卫星钟频差一个量级
% <Springer Handbook of Global Navigation Satellite Systems>564页(19.16)
% 2*miu/c^2=0.00887005737336
dfrel = 0.00887005737336 * (1/a - 1/norm(rs));

% 计算电离层延迟
if ~isnan(iono(1)) %参数有效
    [azi, ele] = aziele_xyz(rs, lla);
    dtiono = Klobuchar1(iono, azi, ele, lla(1), lla(2), te);
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
corr.dfrel = dfrel; %相对论钟频差,s/s
corr.dfsagnac = dfsagnac; %Saganc效应频率差,s/s

end