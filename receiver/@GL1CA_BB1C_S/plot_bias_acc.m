function plot_bias_acc(obj)
% 画加速度计零偏输出

%% 深组合模式
if obj.state==3
    figure('Name','加计零偏')
    for k=1:3
        subplot(3,1,k)
        plot(obj.storage.bias(:,k+3), 'LineWidth',1)
        grid on
    end
end

end