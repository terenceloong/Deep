function plot_carrNco(obj)
% 画载波驱动频率

PRN_str = ['BDS ',sprintf('%d',obj.PRN)];
figure('Name',PRN_str)
t = obj.storage.dataIndex/obj.sampleFreq;
if obj.state==3 %深组合时估计的载波频率作为背景
    plot(t, obj.storage.carrFreq)
    hold on
    plot(t, obj.storage.carrNco)
    legend('估计的载波频率','驱动频率')
else %其他情况驱动频率作为背景
    plot(t, obj.storage.carrNco)
    hold on
    plot(t, obj.storage.carrFreq)
    legend('驱动频率','估计的载波频率')
end
set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
grid on

end