function varargout = plot_carrAcc(obj, varargin)
% 画载波频率变化率

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
    Ts = ceil(obj.Tms/1000);
    f = figure('Position',screenBlock(900,540,0.5,0.5), 'Name',name_str);
    axes('Position',[0.07, 0.55, 0.4, 0.38]) %(1,1)
    set(gca, 'Box','on', 'NextPlot','add')
    grid on
    set(gca, 'XLim',[0,Ts])
    title('载波加速度')
    axes('Position',[0.54, 0.55, 0.4, 0.38]) %(1,2)
    set(gca, 'Box','on', 'NextPlot','add')
    grid on
    set(gca, 'XLim',[0,Ts])
    title('载波加速度积分值')
    axes('Position',[0.07, 0.08, 0.4, 0.38]) %(2,1)
    set(gca, 'Box','on', 'NextPlot','add')
    grid on
    set(gca, 'XLim',[0,Ts])
    title('积分误差')
    axes('Position',[0.54, 0.08, 0.4, 0.38]) %(2,2)
    set(gca, 'Box','on', 'NextPlot','add')
    grid on
    set(gca, 'XLim',[0,Ts])
    title('载波频率')
end

% 画图
ax1 = f.Children(4); %多个图时是倒序
ax2 = f.Children(3);
ax3 = f.Children(2);
ax4 = f.Children(1);
t = obj.storage.dataIndex/obj.sampleFreq;
dt = [diff(t); 0];
carrAccInt = cumsum(obj.storage.carrAcc.*dt); %载波加速度积分值
plot(ax1, t, obj.storage.carrAcc)
plot(ax2, t, carrAccInt)
plot(ax4, t, obj.storage.carrFreq)
plot(ax3, t, obj.storage.carrFreq-carrAccInt)
% 积分误差最好是一条平的直线,如果斜着漂是时钟漂移

if nargout>0
    varargout{1} = f; %将图句柄输出
end

end