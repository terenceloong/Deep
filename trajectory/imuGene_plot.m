% IMU数据生成画图
% IMU数据变量名为imu

t = imu(:,1) - imu(1,1); %时间序列,从0开始

figure
subplot(3,2,1)
plot(t,imu(:,2))
grid on
set(gca, 'xlim', [t(1),t(end)])
subplot(3,2,3)
plot(t,imu(:,3))
grid on
set(gca, 'xlim', [t(1),t(end)])
subplot(3,2,5)
plot(t,imu(:,4))
grid on
set(gca, 'xlim', [t(1),t(end)])
subplot(3,2,2)
plot(t,imu(:,5))
grid on
set(gca, 'xlim', [t(1),t(end)])
subplot(3,2,4)
plot(t,imu(:,6))
grid on
set(gca, 'xlim', [t(1),t(end)])
subplot(3,2,6)
plot(t,imu(:,7))
grid on
set(gca, 'xlim', [t(1),t(end)])

clearvars t