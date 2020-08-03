function plot_carrAcc(obj)
% 画载波频率变化率

PRN_str = ['BDS ',sprintf('%d',obj.PRN)];
figure('Name',PRN_str)
t = obj.storage.dataIndex/obj.sampleFreq;
plot(t, obj.storage.carrAcc, 'LineWidth',0.5)
set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
grid on
title('载波加速度')

PRN_str = ['BDS ',sprintf('%d',obj.PRN)];
figure('Name',PRN_str)
t = obj.storage.dataIndex/obj.sampleFreq;
plot(t, cumsum(obj.storage.carrAcc), 'LineWidth',0.5)
set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
grid on
title('载波加速度的积分')

end