function plot_att(obj)
% 画姿态输出

% 时间轴
t = obj.storage.ta - obj.storage.ta(1);
t = t + obj.Tms/1000 - t(end);

%% 深组合模式
if obj.state==3
    figure('Name','姿态')
%     for k=1:3
%         subplot(3,1,k)
%         plot(t, obj.storage.att(:,k), 'LineWidth',1)
%         grid on
%         set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
%     end
    subplot(3,1,1)
    yaw = obj.storage.att(:,1);
    for k=2:length(yaw)
        if yaw(k)-yaw(k-1)<-180
            yaw(k:end) = yaw(k:end) + 360;
        elseif yaw(k)-yaw(k-1)>180
            yaw(k:end) = yaw(k:end) - 360;
        end
    end
    plot(t, yaw, 'LineWidth',1)
    grid on
    set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
    subplot(3,1,2)
    plot(t, obj.storage.att(:,2), 'LineWidth',1)
    grid on
    set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
    subplot(3,1,3)
    plot(t, obj.storage.att(:,3), 'LineWidth',1)
    grid on
    set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
end

end