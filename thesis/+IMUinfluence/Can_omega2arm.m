% 杆臂长度与角速度的关系曲线
clear
clc

x = 1:1:300; %带宽

C = 2;
y1 = C/2./(x/180*pi);
C = 1;
y2 = C/2./(x/180*pi);
C = 0.5;
y3 = C/2./(x/180*pi);
C = 0.2;
y4 = C/2./(x/180*pi);
C = 0.1;
y5 = C/2./(x/180*pi);

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
xlabel('角速度/(°/s)')
ylabel('杆臂长度/(m)')
set(ax, 'YLim',[0,2])
legend('C_a_\perp=2','C_a_\perp=1','C_a_\perp=0.5','C_a_\perp=0.2','C_a_\perp=0.1', 'Location','northeast')