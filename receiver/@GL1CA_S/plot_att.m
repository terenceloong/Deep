function plot_att(obj)
% »­×ËÌ¬Êä³ö

figure('Name','×ËÌ¬')
switch obj.state
    case {2, 3}
        for k=1:3
            subplot(3,1,k)
            plot(obj.storage.att(:,k), 'LineWidth',1)
            grid on
        end
end

end