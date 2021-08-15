% 杆臂效应补偿引起的伪距率测量噪声标准差与角速度噪声标准差的关系曲线
clear
clc

x = logspace(-3,0,100); %0.001~1deg/s

coef = pi/180;
r = 0.1;
y1 = r*x*coef;
r = 0.5;
y2 = r*x*coef;
r = 1;
y3 = r*x*coef;
r = 2;
y4 = r*x*coef;
r = 5;
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
ylabel('伪距率测量噪声标准差/(m/s)')
legend('0.1m','0.5m','1m','2m','5m', 'Location','northwest')