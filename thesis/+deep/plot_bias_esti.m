% ª≠¡„∆´π¿º∆«˙œﬂ
t = nCoV.storage.ta - nCoV.storage.ta(end) + nCoV.Tms/1000;

%% Õ”¬›“«
figure('Position',[488,200,560,520])

ax = subplot(3,1,1);
h = plot(t, nCoV.storage.bias(:,1)/pi*180, 'LineWidth',2);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('x÷·¡„∆´/(°„/s)')

ax = subplot(3,1,2);
h = plot(t, nCoV.storage.bias(:,2)/pi*180, 'LineWidth',2);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('y÷·¡„∆´/(°„/s)')

ax = subplot(3,1,3);
h = plot(t, nCoV.storage.bias(:,3)/pi*180, 'LineWidth',2);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('z÷·¡„∆´/(°„/s)')
xlabel(' ±º‰/(s)')

%% º”ÀŸ∂»º∆
figure('Position',[488,200,560,520])

ax = subplot(3,1,1);
h = plot(t, nCoV.storage.bias(:,4)*100, 'LineWidth',2);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('x÷·¡„∆´/(mg)')

ax = subplot(3,1,2);
h = plot(t, nCoV.storage.bias(:,5)*100, 'LineWidth',2);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('y÷·¡„∆´/(mg)')

ax = subplot(3,1,3);
h = plot(t, nCoV.storage.bias(:,6)*100, 'LineWidth',2);
grid on
set(ax, 'FontSize',12)
set(ax, 'xlim',[t(1),t(end)])
figureMargin(ax, h, 0.2);
ylabel('z÷·¡„∆´/(mg)')
xlabel(' ±º‰/(s)')