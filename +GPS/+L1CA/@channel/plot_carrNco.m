function plot_carrNco(obj)
% 画载波驱动频率

PRN_str = ['GPS ',sprintf('%d',obj.PRN)];
figure('Name',PRN_str)
t = obj.storage.dataIndex/obj.sampleFreq;
plot(t, obj.storage.carrNco)
set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
grid on

end