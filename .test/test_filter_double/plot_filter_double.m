t = (1:n)'*dti;
r2d = 180/pi;
index = ~isnan(output.satnav(:,1)); %”–Œ¿–«¡ø≤‚µƒÀ˜“˝

%% Œª÷√
figure('Name','Œª÷√ŒÛ≤Ó')

subplot(3,1,1)
y = (output.pos(:,1)-traj(:,7))/r2d/NF.geogInfo.dlatdn;
plot(t,y, 'LineWidth',2)
hold on
grid on
range = max(abs(y))*1.1;
set(gca, 'YLim',[-range,range])
plot(t, output.P(:,7)*3, 'LineStyle','--', 'Color','r')
plot(t,-output.P(:,7)*3, 'LineStyle','--', 'Color','r')

subplot(3,1,2)
y = (output.pos(:,2)-traj(:,8))/r2d/NF.geogInfo.dlonde;
plot(t,y, 'LineWidth',2)
hold on
grid on
range = max(abs(y))*1.1;
set(gca, 'YLim',[-range,range])
plot(t, output.P(:,8)*3, 'LineStyle','--', 'Color','r')
plot(t,-output.P(:,8)*3, 'LineStyle','--', 'Color','r')

subplot(3,1,3)
y = output.pos(:,3) - traj(:,9);
plot(t,y, 'LineWidth',2)
hold on
grid on
range = max(abs(y))*1.1;
set(gca, 'YLim',[-range,range])
plot(t, output.P(:,9)*3, 'LineStyle','--', 'Color','r')
plot(t,-output.P(:,9)*3, 'LineStyle','--', 'Color','r')

%% ÀŸ∂»
figure('Name','ÀŸ∂»ŒÛ≤Ó')

subplot(3,1,1)
y = output.vel(:,1) - traj(:,10);
plot(t,y, 'LineWidth',1)
hold on
grid on
range = max(abs(y))*1.1;
set(gca, 'YLim',[-range,range])
plot(t, output.P(:,4)*3, 'LineStyle','--', 'Color','r')
plot(t,-output.P(:,4)*3, 'LineStyle','--', 'Color','r')

subplot(3,1,2)
y = output.vel(:,2) - traj(:,11);
plot(t,y, 'LineWidth',1)
hold on
grid on
range = max(abs(y))*1.1;
set(gca, 'YLim',[-range,range])
plot(t, output.P(:,5)*3, 'LineStyle','--', 'Color','r')
plot(t,-output.P(:,5)*3, 'LineStyle','--', 'Color','r')

subplot(3,1,3)
y = output.vel(:,3) - traj(:,12);
plot(t,y, 'LineWidth',1)
hold on
grid on
range = max(abs(y))*1.1;
set(gca, 'YLim',[-range,range])
plot(t, output.P(:,6)*3, 'LineStyle','--', 'Color','r')
plot(t,-output.P(:,6)*3, 'LineStyle','--', 'Color','r')

%% ◊ÀÃ¨
figure('Name','◊ÀÃ¨ŒÛ≤Ó')

subplot(3,1,1)
y = attContinuous(output.att(:,1)-traj(:,4));
plot(t,y, 'LineWidth',1)
hold on
grid on
range = max(abs(y))*1.1;
set(gca, 'YLim',[-range,range])
plot(t, output.P(:,1)*r2d*3, 'LineStyle','--', 'Color','r')
plot(t,-output.P(:,1)*r2d*3, 'LineStyle','--', 'Color','r')

subplot(3,1,2)
y = output.att(:,2) - traj(:,5);
plot(t,y, 'LineWidth',1)
hold on
grid on
range = max(abs(y))*1.1;
set(gca, 'YLim',[-range,range])
plot(t, output.P(:,2)*r2d*3, 'LineStyle','--', 'Color','r')
plot(t,-output.P(:,2)*r2d*3, 'LineStyle','--', 'Color','r')

subplot(3,1,3)
y = output.att(:,3) - traj(:,6);
plot(t,y, 'LineWidth',1)
hold on
grid on
range = max(abs(y))*1.1;
set(gca, 'YLim',[-range,range])
plot(t, output.P(:,3)*r2d*3, 'LineStyle','--', 'Color','r')
plot(t,-output.P(:,3)*r2d*3, 'LineStyle','--', 'Color','r')

%% ÷”≤Ó÷”∆µ≤Ó
figure('Name','÷”≤Ó÷”∆µ≤Ó')

subplot(2,1,1)
plot(t(index), output.satnav(index,13))
hold on
grid on
plot(t,output.clk(:,1))

subplot(2,1,2)
plot(t(index), output.satnav(index,14))
hold on
grid on
plot(t,output.clk(:,2))

%% Õ”¬›“«¡„∆´
figure('Name','Õ”¬›¡„∆´(deg/s)')
for k=1:3
    subplot(3,1,k)
    y = output.bias(:,k)*r2d;
    plot(t,y, 'LineWidth',1)
    [ymin, ymax] = bounds(y);
    set(gca, 'YLim',[ymin-(ymax-ymin)*0.1,ymax+(ymax-ymin)*0.1])
    grid on
    hold on
    plot(t,gyroBias(k)+output.P(:,k+11)*r2d*3, 'LineStyle','--', 'Color','r')
    plot(t,gyroBias(k)-output.P(:,k+11)*r2d*3, 'LineStyle','--', 'Color','r')
end

%% º”ÀŸ∂»º∆¡„∆´
figure('Name','º”º∆¡„∆´(m/s^2)')
for k=1:3
    subplot(3,1,k)
    y = output.bias(:,k+3);
    plot(t,y, 'LineWidth',1)
    [ymin, ymax] = bounds(y);
    set(gca, 'YLim',[ymin-(ymax-ymin)*0.1,ymax+(ymax-ymin)*0.1])
    hold on
    grid on
    plot(t,accBias(k)+output.P(:,k+14)*3, 'LineStyle','--', 'Color','r')
    plot(t,accBias(k)-output.P(:,k+14)*3, 'LineStyle','--', 'Color','r')
end