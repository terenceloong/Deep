t = (1:n)'*dti;
r2d = 180/pi;
index = ~isnan(output.satnav(:,1)); %”–Œ¿–«¡ø≤‚µƒÀ˜“˝

%% Œª÷√
figure('Position',screenBlock(900,540,0.5,0.5), 'Name','Œª÷√')

subplot(3,2,1)
plot(t(index), output.satnav(index,1)); hold on; grid on;
plot(t, output.pos(:,1))

subplot(3,2,3)
plot(t(index), output.satnav(index,2)); hold on; grid on;
plot(t, output.pos(:,2))

subplot(3,2,5)
plot(t(index), output.satnav(index,3)); hold on; grid on;
plot(t, output.pos(:,3))

subplot(3,2,2)
dn = (output.pos(:,1)-traj(:,7))/r2d/NF.geogInfo.dlatdn;
plot(t, dn); hold on; grid on;
range = max(abs(dn))*1.2;
set(gca, 'YLim',[-range,range])
plot(t, output.P(:,7)*3, 'LineStyle','--', 'Color','r')
plot(t,-output.P(:,7)*3, 'LineStyle','--', 'Color','r')

subplot(3,2,4)
dn = (output.pos(:,2)-traj(:,8))/r2d/NF.geogInfo.dlonde;
plot(t, dn); hold on; grid on;
range = max(abs(dn))*1.2;
set(gca, 'YLim',[-range,range])
plot(t, output.P(:,8)*3, 'LineStyle','--', 'Color','r')
plot(t,-output.P(:,8)*3, 'LineStyle','--', 'Color','r')

subplot(3,2,6)
dn = output.pos(:,3) - traj(:,9);
plot(t, dn); hold on; grid on;
range = max(abs(dn))*1.2;
set(gca, 'YLim',[-range,range])
plot(t, output.P(:,9)*3, 'LineStyle','--', 'Color','r')
plot(t,-output.P(:,9)*3, 'LineStyle','--', 'Color','r')

%% ÀŸ∂»
figure('Position',screenBlock(900,540,0.5,0.5), 'Name','ÀŸ∂»')

subplot(3,2,1)
plot(t(index), output.satnav(index,7)); hold on; grid on;
plot(t, output.vel(:,1))

subplot(3,2,3)
plot(t(index), output.satnav(index,8)); hold on; grid on;
plot(t, output.vel(:,2))

subplot(3,2,5)
plot(t(index), output.satnav(index,9)); hold on; grid on;
plot(t, output.vel(:,3))

subplot(3,2,2)
dn = output.vel(:,1) - traj(:,10);
plot(t, dn); hold on; grid on;
range = max(abs(dn))*1.2;
set(gca, 'YLim',[-range,range])
plot(t, output.P(:,4)*3, 'LineStyle','--', 'Color','r')
plot(t,-output.P(:,4)*3, 'LineStyle','--', 'Color','r')

subplot(3,2,4)
dn = output.vel(:,2) - traj(:,11);
plot(t, dn); hold on; grid on;
range = max(abs(dn))*1.2;
set(gca, 'YLim',[-range,range])
plot(t, output.P(:,5)*3, 'LineStyle','--', 'Color','r')
plot(t,-output.P(:,5)*3, 'LineStyle','--', 'Color','r')

subplot(3,2,6)
dn = output.vel(:,3) - traj(:,12);
plot(t, dn); hold on; grid on;
range = max(abs(dn))*1.2;
set(gca, 'YLim',[-range,range])
plot(t, output.P(:,6)*3, 'LineStyle','--', 'Color','r')
plot(t,-output.P(:,6)*3, 'LineStyle','--', 'Color','r')

%% ◊ÀÃ¨
figure('Position',screenBlock(900,540,0.5,0.5), 'Name','◊ÀÃ¨')

subplot(3,2,1)
plot(t, attContinuous(output.att(:,1)))
grid on

subplot(3,2,3)
plot(t, output.att(:,2))
grid on

subplot(3,2,5)
plot(t, output.att(:,3))
grid on

subplot(3,2,2)
dn = attContinuous(output.att(:,1)-traj(:,4));
plot(t, dn); hold on; grid on;
range = max(abs(dn))*1.2;
set(gca, 'YLim',[-range,range])
plot(t, output.P(:,1)*r2d*3, 'LineStyle','--', 'Color','r')
plot(t,-output.P(:,1)*r2d*3, 'LineStyle','--', 'Color','r')

subplot(3,2,4)
dn = output.att(:,2) - traj(:,5);
plot(t, dn); hold on; grid on;
range = max(abs(dn))*1.2;
set(gca, 'YLim',[-range,range])
plot(t, output.P(:,2)*r2d*3, 'LineStyle','--', 'Color','r')
plot(t,-output.P(:,2)*r2d*3, 'LineStyle','--', 'Color','r')

subplot(3,2,6)
dn = output.att(:,3) - traj(:,6);
plot(t, dn); hold on; grid on;
range = max(abs(dn))*1.2;
set(gca, 'YLim',[-range,range])
plot(t, output.P(:,3)*r2d*3, 'LineStyle','--', 'Color','r')
plot(t,-output.P(:,3)*r2d*3, 'LineStyle','--', 'Color','r')

%% ÷”≤Ó÷”∆µ≤Ó
figure('Name','÷”≤Ó÷”∆µ≤Ó')

subplot(2,1,1)
plot(t(index), output.satnav(index,13)); hold on; grid on;
plot(t,output.clk(:,1))

subplot(2,1,2)
plot(t(index), output.satnav(index,14)); hold on; grid on;
plot(t,output.clk(:,2))

%% Õ”¬›“«¡„∆´
figure('Name','Õ”¬›¡„∆´(deg/s)')
for k=1:3
    subplot(3,1,k)
    plot(t,[output.imu(:,k),output.bias(:,k)]*r2d)
    grid on
    hold on
    plot(t,gyroBias(k)+output.P(:,k+11)*r2d*3, 'LineStyle','--', 'Color','y', 'LineWidth',1)
    plot(t,gyroBias(k)-output.P(:,k+11)*r2d*3, 'LineStyle','--', 'Color','y', 'LineWidth',1)
    set(gca, 'ylim', [-1,1])
end

%% º”ÀŸ∂»º∆¡„∆´
figure('Name','º”º∆¡„∆´(m/s^2)')
for k=1:3
    subplot(3,1,k)
    plot(t,output.bias(:,k+3), 'LineWidth',0.5)
    axis manual
    hold on
    grid on
    plot(t,accBias(k)+output.P(:,k+14)*3, 'LineStyle','--', 'Color','r')
    plot(t,accBias(k)-output.P(:,k+14)*3, 'LineStyle','--', 'Color','r')
end