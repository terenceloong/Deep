function plot_acc_esti(t, data, bias, sigma)
% data:加速度计零偏估计值,g
% bias:零偏真值,g
% sigma:m/s^2

sigma = sigma/10 *3;

figure('Name','加速度计零偏估计')

subplot(3,1,1)
hold on
grid on
plot(t, data(:,1), 'LineWidth',2)
axis manual
plot(t, bias(1)+sigma(:,1), 'Color','r', 'LineStyle','--')
plot(t, bias(1)-sigma(:,1), 'Color','r', 'LineStyle','--')
set(gca, 'xlim', [t(1),t(end)])
xlabel('\itt\rm(s)')
ylabel('\it\nabla_x\rm(g)')

subplot(3,1,2)
hold on
grid on
plot(t, data(:,2), 'LineWidth',2)
axis manual
plot(t, bias(2)+sigma(:,2), 'Color','r', 'LineStyle','--')
plot(t, bias(2)-sigma(:,2), 'Color','r', 'LineStyle','--')
set(gca, 'xlim', [t(1),t(end)])
xlabel('\itt\rm(s)')
ylabel('\it\nabla_y\rm(g)')

subplot(3,1,3)
hold on
grid on
plot(t, data(:,3), 'LineWidth',2)
axis manual
plot(t, bias(3)+sigma(:,3), 'Color','r', 'LineStyle','--')
plot(t, bias(3)-sigma(:,3), 'Color','r', 'LineStyle','--')
set(gca, 'xlim', [t(1),t(end)])
xlabel('\itt\rm(s)')
ylabel('\it\nabla_z\rm(g)')

end