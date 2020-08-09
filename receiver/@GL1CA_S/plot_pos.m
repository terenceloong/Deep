function plot_pos(obj)
% 画位置输出

%% 正常模式
if obj.state==1
    figure('Name','位置')
    for k=1:3
        subplot(3,1,k)
        plot(obj.storage.pos(:,k))
        grid on
    end
end

%% 紧组合/深组合模式
if obj.state==2 || obj.state==3
    figure('Name','位置')
    for k=1:3
        subplot(3,1,k)
        plot(obj.storage.satnav(:,k))
        hold on
        grid on
        plot(obj.storage.pos(:,k), 'LineWidth',1)
    end
end

end