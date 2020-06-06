function plot_carrAcc(obj)
% 画通道的载波频率变化率
% obj:通道对象

PRN_str = ['PRN ',sprintf('%d',obj.PRN)];
figure('Name',PRN_str)
t = obj.storage.dataIndex/obj.sampleFreq;
plot(t, obj.storage.carrAcc, 'LineWidth',0.5)
set(gca, 'XLim',[1,ceil(obj.Tms/1000)])
grid on
title('载波加速度')

PRN_str = ['PRN ',sprintf('%d',obj.PRN)];
figure('Name',PRN_str)
t = obj.storage.dataIndex/obj.sampleFreq;
plot(t, cumsum(obj.storage.carrAcc), 'LineWidth',0.5)
set(gca, 'XLim',[1,ceil(obj.Tms/1000)])
grid on
title('载波加速度的积分')

end