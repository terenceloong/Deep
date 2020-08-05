function plot_pos(obj)
% 画位置输出

if obj.GPSflag==1
    figure('Name','GPS位置')
    for k=1:3
        subplot(3,1,k)
        plot(obj.storage.satnavGPS(:,k))
        grid on
    end
end

if obj.BDSflag==1
    figure('Name','BDS位置')
    for k=1:3
        subplot(3,1,k)
        plot(obj.storage.satnavBDS(:,k), 'Color',[0.85,0.325,0.098])
        grid on
    end
end

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