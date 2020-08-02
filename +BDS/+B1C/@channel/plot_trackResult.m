function plot_trackResult(obj)
% 画跟踪结果

% 创建画图窗口
PRN_str = ['BDS ',sprintf('%d',obj.PRN)];
figure('Position',screenBlock(1140,670,0.5,0.5), 'Name',PRN_str);
ax1 = axes('Position',[0.08, 0.4, 0.38, 0.53]);
hold(ax1,'on');
axis(ax1,'equal');
title(PRN_str)
ax2 = axes('Position',[0.53, 0.7 , 0.42, 0.25]);
hold(ax2,'on');
ax3 = axes('Position',[0.53, 0.38, 0.42, 0.25]);
hold(ax3,'on');
grid(ax3,'on');
ax4 = axes('Position',[0.53, 0.06, 0.42, 0.25]);
hold(ax4,'on');
grid(ax4,'on');
ax5 = axes('Position',[0.05, 0.06, 0.42, 0.25]);
hold(ax5,'on');
grid(ax5,'on');

t = obj.storage.dataIndex/obj.sampleFreq; %使用采样点计算的时间

% I/Q图
plot(ax1, obj.storage.I_Q(1001:end,1), obj.storage.I_Q(1001:end,4), ...
          'LineStyle','none', 'Marker','.')

% I_P图
plot(ax2, t, double(obj.storage.I_Q(:,1))) %横纵坐标数据类型要一样
set(ax2, 'XLim',[0,ceil(obj.Tms/1000)])

% 载波频率
plot(ax4, t, obj.storage.carrFreq, 'LineWidth',0.5)
set(ax4, 'XLim',[0,ceil(obj.Tms/1000)])

% 载波频率变化率
plot(ax5, t, obj.storage.carrAcc, 'LineWidth',0.5)
set(ax5, 'XLim',[0,ceil(obj.Tms/1000)])

end