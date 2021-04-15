function plot_bias_gyro(obj)
% 画陀螺仪零偏输出

if obj.ns==0 %没有数据直接退出
    return
end

% 时间轴
t = obj.storage.ta - obj.storage.ta(end) + obj.Tms/1000;

if obj.state==3
    figure('Name','陀螺零偏')
    for k=1:3
        subplot(3,1,k)
        plot(t, obj.storage.imu(:,k)/pi*180)
        hold on
        grid on
        plot(t, obj.storage.bias(:,k)/pi*180, 'LineWidth',1)
        set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
    end
end

end