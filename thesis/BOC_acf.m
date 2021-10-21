% 画BOC信号的自相关函数曲线

clear
clc

% BOC(6,1)
chip61 = (-12:12)/12;
acf61 = [0:12,11:-1:0]/12;
acf61(2:2:24) = -acf61(2:2:24);
figure('Position',[490,250,680,500])
plot([-1.5,chip61,1.5], [0,acf61,0], 'LineWidth',1.5)
grid on
hold on

% BOC(1,1)
chip11 = (-2:2)/2;
acf11 = [0,-1,2,-1,0]/2;
plot([-1.5,chip11,1.5], [0,acf11,0], 'LineWidth',1.5)

% BPSK
chip0 = [-1,0,1];
acf0 = [0,1,0];
plot([-1.5,chip0,1.5], [0,acf0,0], 'LineWidth',1.5)

% BOC(1,1) & BOC(6,1)
acf11 = [0:-1:-6, -3:3:12, 9:-3:-6, -5:1:0] /12;
acf1161 = (29*acf11+4*acf61)/33;
plot([-1.5,chip61,1.5], [0,acf1161,0], 'LineWidth',1.5, 'Color',[1,0,1])

ax = gca;
set(ax, 'FontSize',12)
xlabel('码片/(个)')
ylabel('归一化相关值')
legend('BOC(6,1)','BOC(1,1)','BPSK','QMBOC(6,1,4/33)')