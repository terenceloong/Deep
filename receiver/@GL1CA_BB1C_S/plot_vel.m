function plot_vel(obj)
% 画速度输出

if obj.GPSflag==1
    figure('Name','GPS速度')
    for k=1:3
        subplot(3,1,k)
        plot(obj.storage.satnavGPS(:,k+3))
        grid on
    end
end

if obj.BDSflag==1
    figure('Name','BDS速度')
    for k=1:3
        subplot(3,1,k)
        plot(obj.storage.satnavBDS(:,k+3), 'Color',[0.85,0.325,0.098])
        grid on
    end
end

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