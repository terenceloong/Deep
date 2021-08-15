% 杆臂长度与角加速度估计器带宽的关系曲线
clear
clc

x = 5:25; %带宽
Timu = 0.01;

C = 10;
y1 = C./sqrt(2.38*x.^3*Timu);
C = 8;
y2 = C./sqrt(2.38*x.^3*Timu);
C = 6;
y3 = C./sqrt(2.38*x.^3*Timu);
C = 4;
y4 = C./sqrt(2.38*x.^3*Timu);
C = 2;
y5 = C./sqrt(2.38*x.^3*Timu);

figure('Position',[488,242,560,500])
plot(x,y1, 'LineWidth',2)
hold on
grid on
plot(x,y2, 'LineWidth',2)
plot(x,y3, 'LineWidth',2)
plot(x,y4, 'LineWidth',2)
plot(x,y5, 'LineWidth',2)

ax = gca;
set(ax, 'FontSize',12)
xlabel('角加速度估计器带宽/(Hz)')
ylabel('杆臂长度/(m)')
legend('C_a_t=10','C_a_t=8','C_a_t=6','C_a_t=4','C_a_t=2', 'Location','northeast')