function plot_vel(obj)
% 画速度输出

% 时间轴
t = obj.storage.ta - obj.storage.ta(1);
t = t + obj.Tms/1000 - t(end);

%% 正常模式
if obj.state==1
    figure('Name','速度')
    for k=1:3
        subplot(3,1,k)
        plot(t, obj.storage.vel(:,k))
        grid on
        set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
    end
end

%% 紧组合/深组合模式
if obj.state==2 || obj.state==3
    figure('Name','速度')
    for k=1:3
        subplot(3,1,k)
        plot(t, obj.storage.satnav(:,k+3))
        hold on
        grid on
        plot(t, obj.storage.vel(:,k), 'LineWidth',1)
        set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
    end
end

end