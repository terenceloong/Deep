function plot_quality(obj)
% 画信号质量

PRN_str = ['BDS ',sprintf('%d',obj.PRN)];
figure('Position', screenBlock(1000,600,0.5,0.5), 'Name',PRN_str);
ax1 = axes('Position',[0.06, 0.55, 0.88, 0.4]);
hold(ax1,'on');
grid(ax1,'on')
ax2 = axes('Position',[0.06, 0.08, 0.88, 0.4]);
hold(ax2,'on');
grid(ax2,'on')

t = obj.storage.dataIndex/obj.sampleFreq;

% 带信号质量标记的I路输出
quality = obj.storage.quality; %信号质量
I = double(obj.storage.I_Q(:,1)); %I路输出
I1 = I;
I1(quality<1) = NaN; %保留强信号和弱信号
I2 = I;
I2(quality<2) = NaN; %保留强信号

plot(ax1, t, I, 'Color',[0.929,0.694,0.125]) %失锁,黄
plot(ax1, t, I1, 'Color',[0.85,0.325,0.098]) %弱信号,橘黄
plot(ax1, t, I2, 'Color',[0,0.447,0.741]) %强信号,蓝色
set(ax1, 'XLim',[0,ceil(obj.Tms/1000)])

% 带信号质量标记的载波频率
quality = obj.storage.quality; %信号质量
fc = obj.storage.carrFreq; %载波频率
fc1 = fc;
fc1(quality<1) = NaN; %保留强信号和弱信号
fc2 = fc;
fc2(quality<2) = NaN; %保留强信号

plot(ax2, t, fc, 'Color',[0.929,0.694,0.125]) %失锁,黄
plot(ax2, t, fc1, 'Color',[0.85,0.325,0.098]) %弱信号,橘黄
plot(ax2, t, fc2, 'Color',[0,0.447,0.741]) %强信号,蓝色
plot(ax2, t, obj.storage.carrNco+1, 'Color',[0.5,0.5,0.5], 'LineStyle','--') %上界
plot(ax2, t, obj.storage.carrNco-1, 'Color',[0.5,0.5,0.5], 'LineStyle','--') %下界
set(ax2, 'XLim',[0,ceil(obj.Tms/1000)])

end