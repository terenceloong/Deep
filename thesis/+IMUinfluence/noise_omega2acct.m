% 切向加速度噪声标准差与角速度噪声标准差的关系曲线
clear
clc

x = logspace(-3,0,100); %0.001~1deg/s

coef = pi/180;
r = 10;
y1 = r*x*coef;
r = 8;
y2 = r*x*coef;
r = 6;
y3 = r*x*coef;
r = 4;
y4 = r*x*coef;
r = 2;
y5 = r*x*coef;

figure('Position',[488,242,560,500])
loglog(x,y1, 'LineWidth',2)
hold on
grid on
loglog(x,y2, 'LineWidth',2)
loglog(x,y3, 'LineWidth',2)
loglog(x,y4, 'LineWidth',2)
loglog(x,y5, 'LineWidth',2)

ax = gca;
set(ax, 'FontSize',12)
xlabel('角速度噪声标准差/(°/s)')
ylabel('切向加速度噪声标准差/(m/s^2)')
legend('C_a_t=10','C_a_t=8','C_a_t=6','C_a_t=4','C_a_t=2', 'Location','northwest')