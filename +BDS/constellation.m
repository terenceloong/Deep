function ax = constellation(filepath, c, zone, p, ax)
% 画指定时间的BDS星座图,可以接收图像句柄,在其他系统星座图上叠加
% filepath:星历存储的路径,结尾不带\
% c:[year, mon, day, hour, min, sec]
% zone:时区,东半球为正,西半球为负
% p:纬经高,deg
% ax:极坐标轴

% 获取星历(为保证取到星历,下载前一天的数据)
c0 = c;
c0(4) = c0(4) - zone - 24; %调整小时,不在乎正负
date = datestr(c0,'yyyy-mm-dd'); %得到时间字符串
filename = BDS.ephemeris.download(filepath, date);
ephemeris = RINEX.read_B303(filename);

% 提取星历文件的最后一行星历
ephe = NaN(63,16);
for k=1:63
    if isempty(ephemeris.sv{k})
        continue
    end
    ephe(k,1) = ephemeris.sv{k}(end).toe;
    ephe(k,2) = ephemeris.sv{k}(end).sqa;
    ephe(k,3) = ephemeris.sv{k}(end).e;
    ephe(k,4) = ephemeris.sv{k}(end).dn;
    ephe(k,5) = ephemeris.sv{k}(end).M0;
    ephe(k,6) = ephemeris.sv{k}(end).omega;
    ephe(k,7) = ephemeris.sv{k}(end).Omega0;
    ephe(k,8) = ephemeris.sv{k}(end).Omega_dot;
    ephe(k,9) = ephemeris.sv{k}(end).i0;
    ephe(k,10) = ephemeris.sv{k}(end).i_dot;
    ephe(k,11) = ephemeris.sv{k}(end).Cus;
    ephe(k,12) = ephemeris.sv{k}(end).Cuc;
    ephe(k,13) = ephemeris.sv{k}(end).Crs;
    ephe(k,14) = ephemeris.sv{k}(end).Crc;
    ephe(k,15) = ephemeris.sv{k}(end).Cis;
    ephe(k,16) = ephemeris.sv{k}(end).Cic;
end
PRN = find(~isnan(ephe(:,1))); %有数据的卫星号
ephe = ephe(PRN,:); %删除无数据的行

% 使用星历计算所有卫星方位角高度角
t = UTC2BDT(c, zone); %[week,second]
rs = D1.rs_ephe(ephe, t(2));
[azi, ele] = aziele_xyz(rs, p);

% 获取高度角大于0的卫星
index = find(ele>0); %高度角大于0的行号
PRN = PRN(index,1);
azi = azi(index)/180*pi; %方位角转成弧度
ele = ele(index);

% 创建坐标轴
if ~exist('ax','var')
    figure
    ax = polaraxes; %创建极坐标轴
    ax.NextPlot = 'add'; %hold on
    ax.Clipping = 'off'; %关闭剪切功能,让卫星移出坐标轴时还能显示
    ax.RLim = [0,90]; %高度角范围
    ax.RDir = 'reverse'; %高度角里面是90度
%     ax.RTick = [0,15,30,45,60,75,90]; %高度角刻度
    ax.ThetaDir = 'clockwise'; %顺时针方位角增加
    ax.ThetaZeroLocation = 'top'; %方位角0在上
    title(sprintf('%d-%02d-%02d %02d:%02d:%02d UTC%+d', c, zone))
    % 创建一个滑动条,改变高度角显示范围
    sl = uicontrol;
    sl.Style = 'slider';
    sl.Position = [15,15,120,15];
    sl.Max = 80;
    sl.Min = 0;
    sl.SliderStep = [2,8]/80;
    sl.Callback = @changeEleRange;
end
    function changeEleRange(src, ~)
        ax.RLim = [floor(src.Value),90];
    end

% 画图
for k=1:length(PRN)
    if ismember(PRN(k),[19:30,32:46]) %北斗三号
        if ele(k)<10 %低高度角卫星,透明
            polarscatter(ax, azi(k),ele(k), 220, 'MarkerFaceColor',[255,65,65]/255, ...
                         'MarkerEdgeColor',[127,127,127]/255, 'MarkerFaceAlpha',0.5)
            text(azi(k),ele(k),num2str(PRN(k)), 'HorizontalAlignment','center', ...
                                                'VerticalAlignment','middle')
        else
            polarscatter(ax, azi(k),ele(k), 220, 'MarkerFaceColor',[255,65,65]/255, ...
                         'MarkerEdgeColor',[127,127,127]/255)
            text(azi(k),ele(k),num2str(PRN(k)), 'HorizontalAlignment','center', ...
                                                'VerticalAlignment','middle')
        end
    end
end

end