function plot_I_P(obj)
% 画通道的I_P图
% obj:通道对象

PRN_str = ['PRN ',sprintf('%d',obj.PRN)];
figure('Position', screenBlock(1000,300,0.5,0.5), 'Name',PRN_str);
axes('Position', [0.05, 0.15, 0.9, 0.75]);
t = obj.storage.dataIndex/obj.sampleFreq;
plot(t, double(obj.storage.I_Q(:,1)))
set(gca, 'XLim',[1,ceil(obj.Tms/1000)])

end