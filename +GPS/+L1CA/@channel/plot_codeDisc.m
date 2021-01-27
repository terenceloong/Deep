function plot_codeDisc(obj)
% 画码鉴相器输出

PRN_str = ['GPS ',sprintf('%d',obj.PRN)];
figure('Name',PRN_str)
index = isnan(obj.storage.dataIndex) | ~isnan(obj.storage.disc(:,1)); %有效数据的索引
t = obj.storage.dataIndex(index)/obj.sampleFreq;
plot(t, obj.storage.disc(index,1))
set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
grid on

end