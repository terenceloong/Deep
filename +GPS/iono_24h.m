function iono_24h(filepath, date, p, zone, eleMask)
% 计算24h电离层校正量
% 截止高度角越小,电离层校正量的峰值越大
% filepath:星历存储的路径,结尾不带\
% date:日期字符串,'yyyy-mm-dd'
% p:接收机位置,纬经高,deg
% zone:时区,东半球为正,西半球为负
% eleMask:截止高度角,deg
% 参考BDS.constellation

% 获取星历
filename = GPS.ephemeris.download(filepath, date);
ephemeris = RINEX.read_N2(filename);

% 提取星历文件的第一行星历
ephe = NaN(32,16);
for k=1:32
    if isempty(ephemeris.sv{k})
        continue
    end
    ephe(k,1) = ephemeris.sv{k}(1).toe;
    ephe(k,2) = ephemeris.sv{k}(1).sqa;
    ephe(k,3) = ephemeris.sv{k}(1).e;
    ephe(k,4) = ephemeris.sv{k}(1).dn;
    ephe(k,5) = ephemeris.sv{k}(1).M0;
    ephe(k,6) = ephemeris.sv{k}(1).omega;
    ephe(k,7) = ephemeris.sv{k}(1).Omega0;
    ephe(k,8) = ephemeris.sv{k}(1).Omega_dot;
    ephe(k,9) = ephemeris.sv{k}(1).i0;
    ephe(k,10) = ephemeris.sv{k}(1).i_dot;
    ephe(k,11) = ephemeris.sv{k}(1).Cus;
    ephe(k,12) = ephemeris.sv{k}(1).Cuc;
    ephe(k,13) = ephemeris.sv{k}(1).Crs;
    ephe(k,14) = ephemeris.sv{k}(1).Crc;
    ephe(k,15) = ephemeris.sv{k}(1).Cis;
    ephe(k,16) = ephemeris.sv{k}(1).Cic;
end
PRN = find(~isnan(ephe(:,1))); %有数据的卫星号
ephe = ephe(PRN,:); %删除无数据的行

% 提取星历文件中的电离层参数
iono = [ephemeris.alpha, ephemeris.beta];

% 初始时间
c = datevec(date,'yyyy-mm-dd'); %时间矢量
t = UTC2GPS(c, zone); %[week,second]
ts = t(2); %只取秒数

% 计算
n = 30*24; %计算点数,2分钟一个
svN = length(PRN); %卫星个数
dtiono = NaN(n,svN);
for k=1:n
    rs = LNAV.rs_ephe(ephe, ts);
    [azi, ele] = aziele_xyz(rs, p); %计算所有卫星方位角高度角
    for i=1:svN
        if ele(i)>eleMask %高度角要大于截止高度角
            dtiono(k,i) = Klobuchar1(iono, azi(i), ele(i), p(1), p(2), ts);
        end
    end
    ts = ts+120; %加2分钟
end
dtiono = dtiono*299792458; %转化成距离

% 画图
figure('Name','iono_24h')
hold on
grid on
t = (0:n-1)/30; %时间横坐标,单位:小时
for k=1:svN
    f = plot(t,dtiono(:,k), 'Color',[0,0.447,0.741], 'LineWidth',1);
    c = uicontextmenu;
    f.UIContextMenu = c;
    uimenu(c, 'Text',sprintf('%d',PRN(k))); %鼠标右键显示卫星编号
end
set(gca, 'XLim',[0,24])
set(gca, 'YLim',[0,12])

end