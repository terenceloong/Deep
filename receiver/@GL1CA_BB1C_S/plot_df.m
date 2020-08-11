function plot_df(obj)
% ª≠÷”∆µ≤Óπ¿º∆÷µ

%  ±º‰÷·
t = obj.storage.ta - obj.storage.ta(1);
t = t + obj.Tms/1000 - t(end);

figure('Name','÷”∆µ≤Óπ¿º∆')
plot(t, obj.storage.df)
grid on
set(gca, 'XLim',[0,ceil(obj.Tms/1000)])

end