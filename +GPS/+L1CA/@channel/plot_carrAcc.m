function plot_carrAcc(obj)
% 画载波频率变化率

PRN_str = ['GPS ',sprintf('%d',obj.PRN)];
figure('Position',screenBlock(900,540,0.5,0.5), 'Name',PRN_str);
ax1 = axes('Position',[0.07, 0.55, 0.4, 0.38]); %(1,1)
hold(ax1,'on');
grid(ax1,'on');
ax2 = axes('Position',[0.54, 0.55, 0.4, 0.38]); %(1,2)
hold(ax2,'on');
grid(ax2,'on');
ax3 = axes('Position',[0.07, 0.08, 0.4, 0.38]); %(2,1)
hold(ax3,'on');
grid(ax3,'on');
ax4 = axes('Position',[0.54, 0.08, 0.4, 0.38]); %(2,2)
hold(ax4,'on');
grid(ax4,'on');

t = obj.storage.dataIndex/obj.sampleFreq;
dt = [diff(t); 0];
carrAccInt = cumsum(obj.storage.carrAcc.*dt); %载波加速度积分值

plot(ax1, t, obj.storage.carrAcc)
set(ax1, 'XLim',[0,ceil(obj.Tms/1000)])
title(ax1, '载波加速度')
plot(ax2, t, carrAccInt)
set(ax2, 'XLim',[0,ceil(obj.Tms/1000)])
title(ax2, '载波加速度积分值')
plot(ax4, t, obj.storage.carrFreq)
set(ax4, 'XLim',[0,ceil(obj.Tms/1000)])
title(ax4, '载波频率')
plot(ax3, t, obj.storage.carrFreq-carrAccInt)
set(ax3, 'XLim',[0,ceil(obj.Tms/1000)])
title(ax3, '积分误差')
% 积分误差最好是一条平的直线,如果斜着漂是时钟漂移

end