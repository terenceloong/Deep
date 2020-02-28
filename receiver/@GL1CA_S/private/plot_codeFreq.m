function plot_codeFreq(obj)
% 画通道的码频率
% obj:通道对象

PRN_str = ['PRN ',sprintf('%d',obj.PRN)];
figure('Name',PRN_str)
t = obj.storage.dataIndex/obj.sampleFreq;
plot(t, obj.storage.codeFreq)
set(gca, 'XLim',[1,ceil(obj.Tms/1000)])
grid on

end