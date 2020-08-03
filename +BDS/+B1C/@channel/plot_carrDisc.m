function plot_carrDisc(obj)
% »­ÔØ²¨¼øÏàÆ÷Êä³ö

PRN_str = ['BDS ',sprintf('%d',obj.PRN)];
figure('Name',PRN_str)
t = obj.storage.dataIndex/obj.sampleFreq;
plot(t, obj.storage.disc(:,2))
set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
grid on

end