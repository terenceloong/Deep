function plot_df(obj)
% 画钟频差估计值

if obj.ns==0 %没有数据直接退出
    return
end

% 时间轴
t = obj.storage.ta - obj.storage.ta(1);
t = t + obj.Tms/1000 - t(end);

figure('Name','钟频差估计')
plot(t, obj.storage.df)
grid on
set(gca, 'XLim',[0,ceil(obj.Tms/1000)])

end