function plot_codeDisc(obj)
% »­Âë¼øÏàÆ÷Êä³ö

PRN_str = ['GPS ',sprintf('%d',obj.PRN)];
figure('Name',PRN_str)
t = obj.storage.dataIndex/obj.sampleFreq;
plot(t, obj.storage.disc(:,1))
set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
grid on

end