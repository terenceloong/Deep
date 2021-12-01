plot_flag = [1,1,1,1,1,1];
% plot_flag = [0,0,1,0,0,0];

index = ~isnan(output.satnav(:,1)); %”–Œ¿–«¡ø≤‚µƒÀ˜“˝

%% Œª÷√
if plot_flag(1)==1
figure('Name','Œª÷√ŒÛ≤Ó')

subplot(3,1,1)
y = (output.pos(:,1)-nav0(:,1))/NF.geogInfo.Cn2g(1);
plot(t0,y, 'LineWidth',2)
hold on
grid on
range = max(abs(y))*1.1;
set(gca, 'YLim',[-range,range])
plot(t0, output.P(:,7)*3, 'LineStyle','--', 'Color','r')
plot(t0,-output.P(:,7)*3, 'LineStyle','--', 'Color','r')

subplot(3,1,2)
y = (output.pos(:,2)-nav0(:,2))/NF.geogInfo.Cn2g(5);
plot(t0,y, 'LineWidth',2)
hold on
grid on
range = max(abs(y))*1.1;
set(gca, 'YLim',[-range,range])
plot(t0, output.P(:,8)*3, 'LineStyle','--', 'Color','r')
plot(t0,-output.P(:,8)*3, 'LineStyle','--', 'Color','r')

subplot(3,1,3)
y = output.pos(:,3) - nav0(:,3);
plot(t0,y, 'LineWidth',2)
hold on
grid on
range = max(abs(y))*1.1;
set(gca, 'YLim',[-range,range])
plot(t0, output.P(:,9)*3, 'LineStyle','--', 'Color','r')
plot(t0,-output.P(:,9)*3, 'LineStyle','--', 'Color','r')
end

%% ÀŸ∂»
if plot_flag(2)==1
figure('Name','ÀŸ∂»ŒÛ≤Ó')

subplot(3,1,1)
y = output.vel(:,1) - nav0(:,4);
plot(t0,y, 'LineWidth',1)
hold on
grid on
range = max(abs(y))*1.1;
set(gca, 'YLim',[-range,range])
plot(t0, output.P(:,4)*3, 'LineStyle','--', 'Color','r')
plot(t0,-output.P(:,4)*3, 'LineStyle','--', 'Color','r')

subplot(3,1,2)
y = output.vel(:,2) - nav0(:,5);
plot(t0,y, 'LineWidth',1)
hold on
grid on
range = max(abs(y))*1.1;
set(gca, 'YLim',[-range,range])
plot(t0, output.P(:,5)*3, 'LineStyle','--', 'Color','r')
plot(t0,-output.P(:,5)*3, 'LineStyle','--', 'Color','r')

subplot(3,1,3)
y = output.vel(:,3) - nav0(:,6);
plot(t0,y, 'LineWidth',1)
hold on
grid on
range = max(abs(y))*1.1;
set(gca, 'YLim',[-range,range])
plot(t0, output.P(:,6)*3, 'LineStyle','--', 'Color','r')
plot(t0,-output.P(:,6)*3, 'LineStyle','--', 'Color','r')
end

%% ◊ÀÃ¨
if plot_flag(3)==1
r2d = 180/pi;
figure('Name','◊ÀÃ¨ŒÛ≤Ó')

subplot(3,1,1)
y = attContinuous(output.att(:,1)-nav0(:,7));
plot(t0,y, 'LineWidth',1)
hold on
grid on
[ymin, ymax] = bounds(y);
set(gca, 'YLim',[ymin-(ymax-ymin)*0.1,ymax+(ymax-ymin)*0.1])
plot(t0, output.P(:,1)*r2d*3, 'LineStyle','--', 'Color','r')
plot(t0,-output.P(:,1)*r2d*3, 'LineStyle','--', 'Color','r')

subplot(3,1,2)
y = output.att(:,2) - nav0(:,8);
plot(t0,y, 'LineWidth',1)
hold on
grid on
[ymin, ymax] = bounds(y);
set(gca, 'YLim',[ymin-(ymax-ymin)*0.1,ymax+(ymax-ymin)*0.1])
plot(t0, output.P(:,2)*r2d*3, 'LineStyle','--', 'Color','r')
plot(t0,-output.P(:,2)*r2d*3, 'LineStyle','--', 'Color','r')

subplot(3,1,3)
y = output.att(:,3) - nav0(:,9);
plot(t0,y, 'LineWidth',1)
hold on
grid on
[ymin, ymax] = bounds(y);
set(gca, 'YLim',[ymin-(ymax-ymin)*0.1,ymax+(ymax-ymin)*0.1])
plot(t0, output.P(:,3)*r2d*3, 'LineStyle','--', 'Color','r')
plot(t0,-output.P(:,3)*r2d*3, 'LineStyle','--', 'Color','r')
end

%% ÷”≤Ó÷”∆µ≤Ó
if plot_flag(4)==1
figure('Name','÷”≤Ó÷”∆µ≤Ó')

subplot(2,1,1)
plot(t0(index), output.satnav(index,13))
hold on
grid on
plot(t0,output.clk(:,1))

subplot(2,1,2)
plot(t0(index), output.satnav(index,14))
hold on
grid on
plot(t0,output.clk(:,2))
end

%% Õ”¬›“«¡„∆´
if plot_flag(5)==1
r2d = 180/pi;
figure('Name','Õ”¬›¡„∆´(deg/s)')
for k=1:3
    subplot(3,1,k)
    y = output.bias(:,k)*r2d;
    plot(t0,y, 'LineWidth',1)
    [ymin, ymax] = bounds(y);
    set(gca, 'YLim',[ymin-(ymax-ymin)*0.1,ymax+(ymax-ymin)*0.1])
    grid on
    hold on
    plot(t0,gyroBias(k)+output.P(:,k+11)*r2d*3, 'LineStyle','--', 'Color','r')
    plot(t0,gyroBias(k)-output.P(:,k+11)*r2d*3, 'LineStyle','--', 'Color','r')
end
end

%% º”ÀŸ∂»º∆¡„∆´
if plot_flag(6)==1
figure('Name','º”º∆¡„∆´(m/s^2)')
for k=1:3
    subplot(3,1,k)
    y = output.bias(:,k+3);
    plot(t0,y, 'LineWidth',1)
    [ymin, ymax] = bounds(y);
    set(gca, 'YLim',[ymin-(ymax-ymin)*0.1,ymax+(ymax-ymin)*0.1])
    hold on
    grid on
    plot(t0,accBias(k)+output.P(:,k+14)*3, 'LineStyle','--', 'Color','r')
    plot(t0,accBias(k)-output.P(:,k+14)*3, 'LineStyle','--', 'Color','r')
end
end