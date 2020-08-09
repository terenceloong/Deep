function plot_vel(obj)
% 画速度输出

%% 正常模式
if obj.state==1
    % 画单独GPS解算速度
    if obj.GPSflag==1
        figure('Name','GPS速度')
        for k=1:3
            subplot(3,1,k)
            plot(obj.storage.satnavGPS(:,k+3))
            grid on
        end
    end
    % 画单独北斗解算速度
    if obj.BDSflag==1
        figure('Name','BDS速度')
        for k=1:3
            subplot(3,1,k)
            plot(obj.storage.satnavBDS(:,k+3), 'Color',[0.85,0.325,0.098])
            grid on
        end
    end
    % 画GPS和北斗联合解算速度
    if obj.GPSflag==1 && obj.BDSflag==1
        figure('Name','GPS+BDS速度')
        for k=1:3
            subplot(3,1,k)
            plot(obj.storage.satnavGPS(:,k+3))
            hold on
            plot(obj.storage.satnavBDS(:,k+3))
            plot(obj.storage.satnav(:,k+3))
            grid on
        end
    end
end

%% 深组合模式
if obj.state==3
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