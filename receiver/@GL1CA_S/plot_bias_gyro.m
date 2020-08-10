function plot_bias_gyro(obj)
% 画陀螺仪零偏输出

% 时间轴
t = obj.storage.ta - obj.storage.ta(1);
t = t + obj.Tms/1000 - t(end);

%% 紧组合/深组合模式
if obj.state==2 || obj.state==3
    figure('Name','陀螺零偏')
    for k=1:3
        subplot(3,1,k)
        plot(obj.storage.imu(:,k))
        hold on
        grid on
        plot(t, obj.storage.bias(:,k), 'LineWidth',1)
    end
end

end