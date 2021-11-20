function plot_all_drho(obj)
% 画所有通道的伪距误差(伪距减载波相位对应的距离)

if obj.ns==0 %没有数据直接退出
    return
end

% 时间轴
t = obj.storage.ta - obj.storage.ta(end) + obj.Tms/1000;

Lca = 0.190293672798365;
for k=1:length(obj.result.satmeasIndex) %只画有量测的卫星
    i = obj.result.satmeasIndex(k); %索引
    PRN_str = ['GPS ',obj.result.satmeasPRN{k}];
    figure('Name',PRN_str)
    plot(t, obj.storage.satmeas{i}(:,7)-obj.storage.satmeas{i}(:,11)*Lca)
    grid on
    set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
end
    

end