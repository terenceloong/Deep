function plot_I_P(obj)
% ª≠I_PÕº(µº∆µ∑÷¡ø)

PRN_str = ['BDS ',sprintf('%d',obj.PRN)];
figure('Position', screenBlock(1000,300,0.5,0.5), 'Name',PRN_str);
axes('Position', [0.05, 0.15, 0.9, 0.75]);
t = obj.storage.dataIndex/obj.sampleFreq;
plot(t, double(obj.storage.I_Q(:,8)))
set(gca, 'XLim',[0,ceil(obj.Tms/1000)])

end