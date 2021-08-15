% 双天线矢量深组合时,姿态误差裕度与基线长度的关系曲线

l = 0.2:0.1:3; %基线长度
phi = 2*asind(0.2*0.19/2./l); %姿态误差裕度,相位误差裕度0.2周

figure
plot(l,phi, 'LineWidth',2)
grid on
ax = gca;
set(ax, 'FontSize',12)
set(ax, 'Ylim', [0,10])
xlabel('基线长度/(m)')
ylabel('姿态误差裕度/(°)')