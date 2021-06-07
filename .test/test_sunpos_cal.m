% 测试太阳位置计算
% 使用行星星历计算太阳位置
% 输出指定地点指定日期的太阳高度角变化曲线
% planetEphemeris输出International Celestial Reference Frame (ICRF)下的位置
% ICRF与J2000非常接近,https://blog.csdn.net/stk10/article/details/103263324/

%% 位置和日期
date0 = [2021,5,31]; %年月日
dnum0 = datenum(date0(1),date0(2),date0(3)) - 1/3; %起始时刻的时间
p0 = [38.0463, 114.4358, 100];
% p0 = [45.7364, 126.70775, 165];
rp = lla2ecef(p0);
Cen = dcmecef2ned(p0(1), p0(2));

%% 输出
ele = zeros(288,1); %太阳高度角,deg
azi = zeros(288,1); %太阳方位角,deg

%% 计算
for k=1:288 %每隔5分钟一算
    dnum = dnum0+k/288;
    utc = datevec(dnum); %转换成UTC时间矢量
    rs = planetEphemeris(juliandate(utc),'Earth','Sun')*1000; %太阳在ICRF中的位置
    Cie = dcmeci2ecef('IAU-2000/2006',utc);
    rs = rs*Cie'; %太阳在ECEF系下的位置
    rps = rs - rp; %所在点指向太阳的位置矢量
    rpsu = rps / norm(rps);
    rpsu_n = rpsu*Cen';
    ele(k) = -asind(rpsu_n(3));
    azi(k) = atan2d(rpsu_n(2),rpsu_n(1));
end

%% 画图
t = dnum0 + 1/3 + (1:288)'/288;
figure
subplot(2,1,1)
plot(t,ele)
datetick('x',15)
grid on
subplot(2,1,2)
plot(t,attContinuous(azi))
datetick('x',15)
grid on

t = (1:288)'/12;
figure
subplot(2,1,1)
plot(t,ele)
set(gca, 'XLim',[0,24])
grid on
subplot(2,1,2)
plot(t,attContinuous(azi))
set(gca, 'XLim',[0,24])
grid on