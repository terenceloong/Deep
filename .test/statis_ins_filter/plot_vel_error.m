function plot_vel_error(t, data, sigma)
% data;速度误差,m/s
% sigma:m/s

sigma = sigma*3;

figure('Name','速度误差')

subplot(3,1,1)
hold on
grid on
plot(t, data(:,1), 'LineWidth',2)
axis manual
plot(t,  sigma(:,1), 'Color','r', 'LineStyle','--')
plot(t, -sigma(:,1), 'Color','r', 'LineStyle','--')
set(gca, 'xlim', [t(1),t(end)])
xlabel('\itt\rm(s)')
ylabel('\delta\itv_n\rm(m/s)')

subplot(3,1,2)
hold on
grid on
plot(t, data(:,2), 'LineWidth',2)
axis manual
plot(t,  sigma(:,2), 'Color','r', 'LineStyle','--')
plot(t, -sigma(:,2), 'Color','r', 'LineStyle','--')
set(gca, 'xlim', [t(1),t(end)])
xlabel('\itt\rm(s)')
ylabel('\delta\itv_e\rm(m/s)')

subplot(3,1,3)
hold on
grid on
plot(t, data(:,3), 'LineWidth',2)
axis manual
plot(t,  sigma(:,3), 'Color','r', 'LineStyle','--')
plot(t, -sigma(:,3), 'Color','r', 'LineStyle','--')
set(gca, 'xlim', [t(1),t(end)])
xlabel('\itt\rm(s)')
ylabel('\delta\itv_d\rm(m/s)')

end