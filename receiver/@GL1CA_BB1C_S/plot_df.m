function plot_df(obj)
% 画钟频差估计值

if obj.ns==0 %没有数据直接退出
    return
end

% 时间轴
t = obj.storage.ta - obj.storage.ta(end) + obj.Tms/1000;

figure('Name','钟频差估计')
plot(t, obj.storage.df)
grid on
set(gca, 'XLim',[0,ceil(obj.Tms/1000)])

if obj.state==3
    figure('Name','钟差钟频差')
    subplot(2,1,1)
    plot(t, [obj.storage.satnav(:,7),obj.storage.others(:,8)])
    grid on
    subplot(2,1,2)
    plot(t, [obj.storage.satnav(:,8),obj.storage.others(:,9)])
    grid on
end

end