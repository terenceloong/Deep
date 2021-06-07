% 画右旋圆极化的波
clear
clc

t = 0:0.01:2.3;
x = cos(2*pi*t);
z = sin(2*pi*t);
y = t*2.2; %伸长

figure
plot3(x,y,z, 'LineWidth',2)
ax = gca;
ax.YDir = 'reverse';
ax.XAxis.Visible = 'off';
ax.YAxis.Visible = 'off';
ax.ZAxis.Visible = 'off';
ax.Color = 'none';
axis equal
hold on
for k=1:4:length(t)
    plot3([0,x(k)],[y(k),y(k)],[0,z(k)], 'Color',[0.85,0.325,0.098], 'LineWidth',1)
end
plot3([0,0],[0,y(end)+0.5],[0,0], 'Color',[0,0,0], 'LineWidth',1)
plot3([0,-1],[0,0],[0,0], 'Color',[0,0,0], 'LineWidth',1)
plot3([0,0],[0,0],[0,1], 'Color',[0,0,0], 'LineWidth',1)