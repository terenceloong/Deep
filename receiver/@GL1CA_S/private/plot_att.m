function plot_att(obj)
% 画姿态输出
% obj:接收机对象

figure('Name','姿态')
switch obj.state
    case 2
        for k=1:3
            subplot(3,1,k)
            plot(obj.storage.att(:,k), 'LineWidth',1)
            grid on
        end
    case 3
end

end