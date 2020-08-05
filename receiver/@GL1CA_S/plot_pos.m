function plot_pos(obj)
% ª≠Œª÷√ ‰≥ˆ

figure('Name','Œª÷√')
switch obj.state
    case 1
        for k=1:3
            subplot(3,1,k)
            plot(obj.storage.pos(:,k))
            grid on
        end
    case 2
        for k=1:3
            subplot(3,1,k)
            plot(obj.storage.satnav(:,k))
            hold on
            grid on
            plot(obj.storage.pos(:,k), 'LineWidth',1)
        end
    case 3
        for k=1:3
            subplot(3,1,k)
            plot(obj.storage.pos(:,k), 'LineWidth',1)
            grid on
        end
end

end