% 画地理系下的加速度

t = nCoV.storage.ta - nCoV.storage.ta(end) + nCoV.Tms/1000;
figure('Position',[488,200,560,520])

ax = subplot(3,1,1);
h = plot(t, nCoV.storage.others(:,10), 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('北向加速度/(m/s^2)')

ax = subplot(3,1,2);
h = plot(t, nCoV.storage.others(:,11), 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('东向加速度/(m/s^2)')

ax = subplot(3,1,3);
h = plot(t, nCoV.storage.others(:,12), 'LineWidth',1.5);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('地向加速度/(m/s^2)')
xlabel('时间/(s)')