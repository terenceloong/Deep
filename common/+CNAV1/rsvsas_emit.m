function [rsvsas, corr] = rsvsas_emit(ephe, te0, rp, iono, lla)
% 计算卫星在信号发射时刻的位置速度加速度,计算伪距伪距率校正量
% ephe:26参数星历(19+7)
% te0:信号名义发射时间,[s,ms,us]
% rp:接收机ecef位置(大致),用于计算Sagnac校正
% iono:电离层校正参数,NaN表示无效
% lla:接收机纬经高,与rp对应,deg
% rsvsas:卫星ecef位置速度加速度,[x,y,z,vx,vy,vz,ax,ay,az]
% corr:伪距伪距率校正量,结构体

% 检查星历参数个数
if length(ephe)~=26
    error('Ephemeris error!')
end

% 地球参数
w = 7.292115e-5;
c = 299792458;

% 提取星历参数
toc = ephe(20);
af0 = ephe(21);
af1 = ephe(22);
af2 = ephe(23);
TGD = ephe(26);
ephe0 = ephe(1:19); %19参数星历,用于计算卫星位置速度

% 计算半长轴
SatType = ephe(2);
dA = ephe(3);
if SatType==1 || SatType==2
    Aref = 42162200; %IGSO/GEO
elseif SatType==3
    Aref = 27906100; %MEO
end
a = Aref + dA; %参考时刻的长半轴

% 计算卫星钟差
dt = te0(1) - toc + te0(2)/1e3 + te0(3)/1e6; %s
dt = mod(dt+302400,604800)-302400; %限制在±302400
dtsv = af0 + af1*dt + af2*dt^2; %卫星钟差,s
dfsv = af1 + 2*af2*dt; %卫星钟频差,s/s

% 信号实际发射时间(钟快了往下减)
te = te0(3)/1e6 - dtsv + te0(2)/1e3 + te0(1); %s

% 计算卫星位置速度
[rsvsas, dtrel] = CNAV1.rsvsas_ephe(ephe0, te);

% 计算Saganc效应校正项
rs = rsvsas(1:3);
dtsagnac = (rs(1)*rp(2)-rs(2)*rp(1))*w/c^2;

% 计算相对论效应引起的卫星钟频差
dfrel = 0.00887005737336 * (1/a - 1/norm(rs));

% 计算电离层延迟
if ~isnan(iono(1)) %参数有效
    dtiono = 0;
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

end