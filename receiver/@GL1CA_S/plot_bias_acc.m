function plot_bias_acc(obj)
% 画加速度计零偏输出

if obj.ns==0 %没有数据直接退出
    return
end

% 时间轴
t = obj.storage.ta - obj.storage.ta(end) + obj.Tms/1000;

if obj.state==2 || obj.state==3
    figure('Name','加计零偏')
    for k=1:3
        subplot(3,1,k)
        plot(t, obj.storage.bias(:,k+3), 'LineWidth',1)
        grid on
        set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
    end
end

end