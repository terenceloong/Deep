function plot_att(obj)
% 画姿态输出

%% 深组合模式
if obj.state==3
    figure('Name','姿态')
    for k=1:3
        subplot(3,1,k)
        plot(obj.storage.att(:,k), 'LineWidth',1)
        grid on
    end
end

end