function ax = constellation(filepath, c, zone, p, ax)
% 画指定时间的GPS星座图,可以接收图像句柄,在其他系统星座图上叠加
% filepath:历书存储的路径,结尾不带\
% c:[year, mon, day, hour, min, sec]
% zone:时区,东半球为正,西半球为负
% p:纬经高,deg
% ax:极坐标轴

% 获取历书
t = UTC2GPS(c, zone); %[week,second]
filename = GPS.almanac.download(filepath, t); %获取历书
almanac = GPS.almanac.read(filename); %读历书文件

% 使用历书计算所有卫星方位角高度角
aziele = aziele_almanac(almanac(:,6:end), t(2), p); %[azi,ele]

% 获取高度角大于0的卫星
index = find(aziele(:,2)>0); %高度角大于0的行号
PRN = almanac(index,1);
azi = mod(aziele(index,1),360)/180*pi; %方位角转成弧度,0~360度
ele = aziele(index,2);

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
    if ele(k)<10 %低高度角卫星,透明
        polarscatter(ax, azi(k),ele(k), 220, 'MarkerFaceColor',[65,180,250]/255, ...
                     'MarkerEdgeColor',[127,127,127]/255, 'MarkerFaceAlpha',0.5)
        text(azi(k),ele(k),num2str(PRN(k)), 'HorizontalAlignment','center', ...
                                            'VerticalAlignment','middle')
    else
        polarscatter(ax, azi(k),ele(k), 220, 'MarkerFaceColor',[65,180,250]/255, ...
                     'MarkerEdgeColor',[127,127,127]/255)
        text(azi(k),ele(k),num2str(PRN(k)), 'HorizontalAlignment','center', ...
                                            'VerticalAlignment','middle')
    end
end

end