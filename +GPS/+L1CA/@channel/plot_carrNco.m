function plot_carrNco(obj, varargin)
% 画载波驱动频率

if nargin==1
    name_str = ['GPS ',sprintf('%d',obj.PRN)];
elseif ischar(varargin{1})
    name_str = ['GPS ',sprintf('%d',obj.PRN),varargin{1}];
else
    return
end

% 新建figure
figure('Name',name_str)
axes('Box','on', 'NextPlot','add')
grid on
set(gca, 'XLim',[0,ceil(obj.Tms/1000)])

% 画图
t = obj.storage.dataIndex/obj.sampleFreq;
if obj.state==3 %矢量跟踪时估计的载波频率作为背景
    plot(t, obj.storage.carrFreq)
    plot(t, obj.storage.carrNco)
    legend('估计的载波频率','驱动频率')
else %其他情况驱动频率作为背景
    plot(t, obj.storage.carrNco)
    plot(t, obj.storage.carrFreq)
    legend('驱动频率','估计的载波频率')
end

end