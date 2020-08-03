function plot_codeFreq(obj)
% »­ÂëÆµÂÊ

PRN_str = ['GPS ',sprintf('%d',obj.PRN)];
figure('Name',PRN_str)
t = obj.storage.dataIndex/obj.sampleFreq;
plot(t, obj.storage.codeFreq)
set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
grid on

end