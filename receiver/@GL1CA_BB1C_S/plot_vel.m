function plot_vel(obj)
% 画速度输出

if obj.ns==0 %没有数据直接退出
    return
end

% 时间轴
t = obj.storage.ta - obj.storage.ta(1);
t = t + obj.Tms/1000 - t(end);

%% 正常模式
if obj.state==1
    % 画单独GPS解算速度
    if obj.GPSflag==1
        figure('Name','GPS速度')
        for k=1:3
            subplot(3,1,k)
            plot(t, obj.storage.satnavGPS(:,k+3))
            grid on
            set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
        end
    end
    % 画单独北斗解算速度
    if obj.BDSflag==1
        figure('Name','BDS速度')
        for k=1:3
            subplot(3,1,k)
            plot(t, obj.storage.satnavBDS(:,k+3), 'Color',[0.85,0.325,0.098])
            grid on
            set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
        end
    end
    % 画GPS和北斗联合解算速度
    if obj.GPSflag==1 && obj.BDSflag==1
        figure('Name','GPS+BDS速度')
        for k=1:3
            subplot(3,1,k)
            plot(t, obj.storage.satnavGPS(:,k+3))
            hold on
            grid on
            plot(t, obj.storage.satnavBDS(:,k+3))
            plot(t, obj.storage.satnav(:,k+3))
            set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
        end
    end
end

%% 深组合模式
if obj.state==3
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