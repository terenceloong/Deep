function plot_vel(obj)
% 画速度输出

%% 正常模式
if obj.state==1
    figure('Name','速度')
    for k=1:3
        subplot(3,1,k)
        plot(obj.storage.vel(:,k))
        grid on
    end
end

%% 紧组合/深组合模式
if obj.state==2 || obj.state==3
    figure('Name','速度')
    for k=1:3
        subplot(3,1,k)
        plot(obj.storage.satnav(:,k+3))
        hold on
        grid on
        plot(obj.storage.vel(:,k), 'LineWidth',1)
    end
end

end