function plot_svnum(obj)
% 画可见卫星数量

if obj.ns==0 %没有数据直接退出
    return
end

% 时间轴
t = obj.storage.ta - obj.storage.ta(end) + obj.Tms/1000;

figure('Name','可见卫星数量')
plot(t, obj.result.svnum(:,2),  'LineWidth',1)
grid on
set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
set(gca, 'YLim',[0,max(obj.result.svnum(:,2))+1])

end