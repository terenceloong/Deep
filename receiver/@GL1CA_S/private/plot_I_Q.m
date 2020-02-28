function plot_I_Q(obj)
% 画通道的I/Q图
% obj:通道对象

PRN_str = ['PRN ',sprintf('%d',obj.PRN)];
figure('Name',PRN_str)
plot(obj.storage.I_Q(1001:end,1), obj.storage.I_Q(1001:end,4), ...
     'LineStyle','none', 'Marker','.')
axis equal

end