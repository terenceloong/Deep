function plot_gyro_esti(t, data, bias, sigma)
% data:Õ”¬›“«¡„∆´π¿º∆÷µ,deg/s
% bias:¡„∆´’Ê÷µ,deg/s
% sigma:rad/s

sigma = sigma/pi*180 *3;

figure('Name','Õ”¬›“«¡„∆´π¿º∆')

subplot(3,1,1)
hold on
grid on
plot(t, data(:,1), 'LineWidth',2)
axis manual
plot(t, bias(1)+sigma(:,1), 'Color','r', 'LineStyle','--')
plot(t, bias(1)-sigma(:,1), 'Color','r', 'LineStyle','--')
set(gca, 'xlim', [t(1),t(end)])
xlabel('\itt\rm(s)')
ylabel('\it\epsilon_x\rm(\circ/s)')

subplot(3,1,2)
hold on
grid on
plot(t, data(:,2), 'LineWidth',2)
axis manual
plot(t, bias(2)+sigma(:,2), 'Color','r', 'LineStyle','--')
plot(t, bias(2)-sigma(:,2), 'Color','r', 'LineStyle','--')
set(gca, 'xlim', [t(1),t(end)])
xlabel('\itt\rm(s)')
ylabel('\it\epsilon_y\rm(\circ/s)')

subplot(3,1,3)
hold on
grid on
plot(t, data(:,3), 'LineWidth',2)
axis manual
plot(t, bias(3)+sigma(:,3), 'Color','r', 'LineStyle','--')
plot(t, bias(3)-sigma(:,3), 'Color','r', 'LineStyle','--')
set(gca, 'xlim', [t(1),t(end)])
xlabel('\itt\rm(s)')
ylabel('\it\epsilon_z\rm(\circ/s)')

end