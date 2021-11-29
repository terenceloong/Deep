function plot_quality(obj, varargin)
% 画信号质量

if nargin==1
    name_str = ['GPS ',sprintf('%d',obj.PRN)];
elseif ischar(varargin{1})
    name_str = ['GPS ',sprintf('%d',obj.PRN),varargin{1}];
else
    return
end

% 新建figure
figure('Position', screenBlock(1000,600,0.5,0.5), 'Name',name_str);
ax1 = axes('Position',[0.06, 0.55, 0.88, 0.4]);
set(ax1, 'Box','on', 'NextPlot','add')
grid on
ax2 = axes('Position',[0.06, 0.08, 0.88, 0.4]);
set(ax2, 'Box','on', 'NextPlot','add')
grid on

t = obj.storage.dataIndex/obj.sampleFreq;
CN0 = obj.storage.CN0; %载噪比

% 带信号质量标记的I路输出
I0 = double(obj.storage.I_Q(:,1)); %I路输出
I1 = I0;
I1(CN0<18) = NaN;
I2 = I0;
I2(CN0<24) = NaN;
I3 = I0;
I3(CN0<37) = NaN;

plot(ax1, t, I0, 'Color',[0.466,0.674,0.188]) %失锁,绿
plot(ax1, t, I1, 'Color',[0.929,0.694,0.125]) %极弱信号,黄
plot(ax1, t, I2, 'Color',[0.850,0.325,0.098]) %弱信号,橘黄
plot(ax1, t, I3, 'Color',[    0,0.447,0.741]) %强信号,蓝色
set(ax1, 'XLim',[0,ceil(obj.Tms/1000)])

% 带信号质量标记的载波频率
fc0 = obj.storage.carrFreq; %载波频率
fc1 = fc0;
fc1(CN0<18) = NaN;
fc2 = fc0;
fc2(CN0<24) = NaN;
fc3 = fc0;
fc3(CN0<37) = NaN;

plot(ax2, t, fc0, 'Color',[0.466,0.674,0.188]) %失锁,绿
plot(ax2, t, fc1, 'Color',[0.929,0.694,0.125]) %极弱信号,黄
plot(ax2, t, fc2, 'Color',[0.850,0.325,0.098]) %弱信号,橘黄
plot(ax2, t, fc3, 'Color',[    0,0.447,0.741]) %强信号,蓝色
plot(ax2, t, obj.storage.carrNco+1, 'Color',[0.5,0.5,0.5], 'LineStyle','--') %上界
plot(ax2, t, obj.storage.carrNco-1, 'Color',[0.5,0.5,0.5], 'LineStyle','--') %下界
set(ax2, 'XLim',[0,ceil(obj.Tms/1000)])

end