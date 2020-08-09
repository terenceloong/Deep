function plot_pos(obj)
% 画位置输出

%% 正常模式
if obj.state==1
    % 画单独GPS解算位置
    if obj.GPSflag==1
        figure('Name','GPS位置')
        for k=1:3
            subplot(3,1,k)
            plot(obj.storage.satnavGPS(:,k))
            grid on
        end
    end
    % 画单独北斗解算位置
    if obj.BDSflag==1
        figure('Name','BDS位置')
        for k=1:3
            subplot(3,1,k)
            plot(obj.storage.satnavBDS(:,k), 'Color',[0.85,0.325,0.098])
            grid on
        end
    end
    % 画GPS和北斗联合解算速度
    if obj.GPSflag==1 && obj.BDSflag==1
        figure('Name','GPS+BDS位置')
        for k=1:3
            subplot(3,1,k)
            plot(obj.storage.satnavGPS(:,k))
            hold on
            plot(obj.storage.satnavBDS(:,k))
            plot(obj.storage.satnav(:,k))
            grid on
        end
    end
end

%% 深组合模式
if obj.state==3
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