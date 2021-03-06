function visibility(filepath, c, zone, p, h)
% 在星座图上画一段时间的卫星轨迹,2分钟一个点
% filepath:历书存储的路径,结尾不带\
% c:[year, mon, day, hour, min, sec]
% zone:时区,东半球为正,西半球为负
% p:纬经高,deg
% h:持续时间,小时

% 获取历书
t = UTC2GPS(c, zone); %[week,second]
filename = GPS.almanac.download(filepath, t); %获取历书
almanac = GPS.almanac.read(filename); %读历书文件

% 使用历书计算所有卫星方位角高度角
svN = size(almanac,1); %卫星数
n = h*30; %点数
azi = zeros(svN,n); %每一列为一个时间点
ele = zeros(svN,n);
ts = t(2); %周内秒数
for k=1:n
    rs = rs_almanac(almanac(:,5:end), t);
    [azi(:,k), ele(:,k)] = aziele_xyz(rs, p);
    ts = ts+120; %更新时间
end

% 获取高度角大于0的卫星
index = zeros(1,svN, 'logical'); %可见卫星索引
for k=1:svN
    if sum(ele(k,:)>0)~=0 %存在高度角大于0的时间段
        index(k) = 1;
    end
end
PRN = almanac(index,1);
azi = azi(index,:)/180*pi; %方位角转成弧度
ele = ele(index,:);

% 创建坐标轴
figure
ax = polaraxes; %创建极坐标轴
ax.NextPlot = 'add'; %hold on
ax.RLim = [0,90]; %高度角范围
ax.RDir = 'reverse'; %高度角里面是90度
ax.RTick = [0,15,30,45,60,75,90]; %高度角刻度
ax.ThetaDir = 'clockwise'; %顺时针方位角增加
ax.ThetaZeroLocation = 'top'; %方位角0在上

% 画图轨迹线
for k=1:length(PRN)
    polarplot(azi(k,:),ele(k,:), 'Color',[0,0.447,0.741], 'LineWidth',1)
end

% 画端点
for k=1:length(PRN)
    if ele(k,1)>0 %起点高度角大于0,画起点,颜色深
        polarscatter(azi(k,1),ele(k,1), 220, 'MarkerFaceColor',[65,180,250]/255, ...
                     'MarkerEdgeColor',[127,127,127]/255, 'MarkerFaceAlpha',0.8)
        text(azi(k,1),ele(k,1),num2str(PRN(k)), 'HorizontalAlignment','center', ...
                                                'VerticalAlignment','middle')
        continue %起点终点只画一个
    end
    if ele(k,end)>0 %终点高度角大于0,画终点,颜色浅
        polarscatter(azi(k,end),ele(k,end), 220, 'MarkerFaceColor',[65,180,250]/255, ...
                     'MarkerEdgeColor',[127,127,127]/255, 'MarkerFaceAlpha',0.3)
        text(azi(k,end),ele(k,end),num2str(PRN(k)), 'HorizontalAlignment','center', ...
                                                    'VerticalAlignment','middle')
    end
end

end