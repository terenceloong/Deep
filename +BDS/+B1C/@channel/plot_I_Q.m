function plot_I_Q(obj)
% 画I/Q图(数据分量I路,导频分量Q路)

PRN_str = ['BDS ',sprintf('%d',obj.PRN)];
figure('Name',PRN_str)
plot(obj.storage.I_Q(1001:end,7), obj.storage.I_Q(1001:end,8), ...
     'LineStyle','none', 'Marker','.')
axis equal

end