function plot_bias_acc(obj)
% 画加速度计零偏输出

% 时间轴
t = obj.storage.ta - obj.storage.ta(1);
t = t + obj.Tms/1000 - t(end);

%% 深组合模式
if obj.state==3
    figure('Name','加计零偏')
    for k=1:3
        subplot(3,1,k)
        plot(t, obj.storage.bias(:,k+3), 'LineWidth',1)
        grid on
        set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
    end
end

end