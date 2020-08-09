function plot_bias_gyro(obj)
% 画陀螺仪零偏输出

%% 深组合模式
if obj.state==3
    figure('Name','陀螺零偏')
    for k=1:3
        subplot(3,1,k)
        plot(obj.storage.imu(:,k))
        hold on
        grid on
        plot(obj.storage.bias(:,k), 'LineWidth',1)
    end
end

end