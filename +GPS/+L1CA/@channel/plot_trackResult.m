function varargout = plot_trackResult(obj, varargin)
% 画跟踪结果

flag = 1;
if nargin==1
    name_str = ['GPS ',sprintf('%d',obj.PRN)];
elseif ischar(varargin{1})
    name_str = ['GPS ',sprintf('%d',obj.PRN),varargin{1}];
elseif isgraphics(varargin{1})
    f = varargin{1};
    flag = 0;
else
    return
end

% 新建figure
if flag==1
    f = figure('Position',screenBlock(1140,670,0.5,0.5), 'Name',name_str);
    axes('Position',[0.08, 0.4, 0.38, 0.53]) %(1,1)
    set(gca, 'Box','on', 'NextPlot','add')
    axis equal
    title(name_str)
    axes('Position',[0.53, 0.7 , 0.42, 0.25]) %(1,2)
    set(gca, 'Box','on', 'NextPlot','add')
    set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
    title('I_P')
    axes('Position',[0.53, 0.38, 0.42, 0.25]) %(2,2)
    set(gca, 'Box','on', 'NextPlot','add')
    grid on
    set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
    set(gca, 'YLim',[0,60])
    title('载噪比')
    axes('Position',[0.53, 0.06, 0.42, 0.25]) %(3,2)
    set(gca, 'Box','on', 'NextPlot','add')
    grid on
    set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
    title('载波频率')
    axes('Position',[0.05, 0.06, 0.42, 0.25]) %(2,1)
    set(gca, 'Box','on', 'NextPlot','add')
    grid on
    set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
    title('载波频率变化率')
end


% 画图
ax1 = f.Children(5); %多个图时是倒序
ax2 = f.Children(4);
ax3 = f.Children(3);
ax4 = f.Children(2);
ax5 = f.Children(1);
t = obj.storage.dataIndex/obj.sampleFreq; %使用采样点计算的时间
% I/Q图
plot(ax1, obj.storage.I_Q(1001:end,1), obj.storage.I_Q(1001:end,4), 'LineStyle','none', 'Marker','.')
% I_P图
plot(ax2, t, double(obj.storage.I_Q(:,1))) %横纵坐标数据类型要一样
% 载噪比
index = isnan(obj.storage.dataIndex) | obj.storage.bitFlag~=0; %有效数据的索引
plot(ax3, t(index), obj.storage.CN0(index), 'LineWidth',0.5)
% 载波频率
plot(ax4, t, obj.storage.carrFreq, 'LineWidth',0.5)
% 载波频率变化率
plot(ax5, t, obj.storage.carrAcc, 'LineWidth',0.5)

if nargout>0
    varargout{1} = f; %将图句柄输出
end

end