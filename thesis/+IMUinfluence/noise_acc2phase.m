% 加速度相位抖动与加速度噪声标准差的关系曲线
clear
clc

x = logspace(-3,0,100); %0.001~1m/s^2
Timu = 0.01;

coef = 5*360; %相位单位是度,5为波长系数
Bn = 25;
y1 = sqrt(Timu/19.1/Bn^3)*x*coef;
Bn = 20;
y2 = sqrt(Timu/19.1/Bn^3)*x*coef;
Bn = 15;
y3 = sqrt(Timu/19.1/Bn^3)*x*coef;
Bn = 10;
y4 = sqrt(Timu/19.1/Bn^3)*x*coef;
Bn = 5;
y5 = sqrt(Timu/19.1/Bn^3)*x*coef;

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
xlabel('加速度噪声标准差/(m/s^2)')
ylabel('加速度相位抖动/(°,1\sigma)')
legend('25Hz','20Hz','15Hz','10Hz','5Hz', 'Location','northwest')
set(ax, 'YLim',[2e-4,5])