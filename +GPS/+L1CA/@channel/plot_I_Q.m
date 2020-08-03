function plot_I_Q(obj)
% »­I/QÍ¼

PRN_str = ['GPS ',sprintf('%d',obj.PRN)];
figure('Name',PRN_str)
plot(obj.storage.I_Q(1001:end,1), obj.storage.I_Q(1001:end,4), ...
     'LineStyle','none', 'Marker','.')
axis equal

end