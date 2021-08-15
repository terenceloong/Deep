% 计算滤波器结果与仿真器基准值的误差

trec = time*[1;1e-3;1e-6] - t0; %接收时间序列,从0开始
tsim = motionSim(:,1) - t0; %基准值时间序列,从0开始

%% 画位置曲线
figure('Name','位置')
for k=1:3
    subplot(3,1,k)
    plot(trec,posF(:,k))
    hold on
    plot(tsim,motionSim(:,k+1))
    ax = gca;
    set(ax, 'XLim',[trec(1),trec(end)])
    grid on
end

%% 画速度曲线
figure('Name','速度')
for k=1:3
    subplot(3,1,k)
    plot(trec,velF(:,k))
    hold on
    plot(tsim,motionSim(:,k+4))
    ax = gca;
    set(ax, 'XLim',[trec(1),trec(end)])
    grid on
end

%% 画加速度曲线
figure('Name','加速度')
for k=1:3
    subplot(3,1,k)
    plot(trec,accF(:,k))
    hold on
    plot(tsim,motionSim(:,k+7))
    ax = gca;
    set(ax, 'XLim',[trec(1),trec(end)])
    grid on
end

%% 计算误差
P1 = griddedInterpolant(tsim,motionSim(:,2),'pchip');
P2 = griddedInterpolant(tsim,motionSim(:,3),'pchip');
P3 = griddedInterpolant(tsim,motionSim(:,4),'pchip');
V1 = griddedInterpolant(tsim,motionSim(:,5),'pchip');
V2 = griddedInterpolant(tsim,motionSim(:,6),'pchip');
V3 = griddedInterpolant(tsim,motionSim(:,7),'pchip');
A1 = griddedInterpolant(tsim,motionSim(:,8),'pchip');
A2 = griddedInterpolant(tsim,motionSim(:,9),'pchip');
A3 = griddedInterpolant(tsim,motionSim(:,10),'pchip');

dP1 = posF(:,1) - P1(trec); dP1 = dP1/180*pi*6378137;
dP2 = posF(:,2) - P2(trec); dP2 = dP2/180*pi*6378137.*cosd(posF(:,1));
dP3 = posF(:,3) - P3(trec);
dV1 = velF(:,1) - V1(trec);
dV2 = velF(:,2) - V2(trec);
dV3 = velF(:,3) - V3(trec);
dA1 = accF(:,1) - A1(trec);
dA2 = accF(:,2) - A2(trec);
dA3 = accF(:,3) - A3(trec);

%% 画位置误差
figure('Position',[488,260,560,500])
subplot(3,1,1)
plot(trec,dP1, 'LineWidth',1)
grid on
ax = gca;
set(ax, 'FontSize',12)
set(ax, 'XLim',[trec(1),trec(end)])
ylabel({'北向位置误差';'/(m)'})

subplot(3,1,2)
plot(trec,dP2, 'LineWidth',1)
grid on
ax = gca;
set(ax, 'FontSize',12)
set(ax, 'XLim',[trec(1),trec(end)])
ylabel({'东向位置误差';'/(m)'})

subplot(3,1,3)
plot(trec,dP3, 'LineWidth',1)
grid on
ax = gca;
set(ax, 'FontSize',12)
set(ax, 'XLim',[trec(1),trec(end)])
xlabel('时间/(s)')
ylabel({'高度误差';'/(m)'})

%% 画速度误差
figure('Position',[488,260,560,500])
subplot(3,1,1)
plot(trec,dV1, 'LineWidth',1)
grid on
ax = gca;
set(ax, 'FontSize',12)
set(ax, 'XLim',[trec(1),trec(end)])
ylabel({'北向速度误差';'/(m/s)'})

subplot(3,1,2)
plot(trec,dV2, 'LineWidth',1)
grid on
ax = gca;
set(ax, 'FontSize',12)
set(ax, 'XLim',[trec(1),trec(end)])
ylabel({'东向速度误差';'/(m/s)'})

subplot(3,1,3)
plot(trec,dV3, 'LineWidth',1)
grid on
ax = gca;
set(ax, 'FontSize',12)
set(ax, 'XLim',[trec(1),trec(end)])
xlabel('时间/(s)')
ylabel({'地向速度误差';'/(m/s)'})

%% 画加速度误差
figure('Position',[488,260,560,500])
subplot(3,1,1)
plot(trec,dA1, 'LineWidth',1)
grid on
ax = gca;
set(ax, 'FontSize',12)
set(ax, 'XLim',[trec(1),trec(end)])
ylabel({'北向加速度误差';'/(m/s^2)'})

subplot(3,1,2)
plot(trec,dA2, 'LineWidth',1)
grid on
ax = gca;
set(ax, 'FontSize',12)
set(ax, 'XLim',[trec(1),trec(end)])
ylabel({'东向加速度误差';'/(m/s^2)'})

subplot(3,1,3)
plot(trec,dA3, 'LineWidth',1)
grid on
ax = gca;
set(ax, 'FontSize',12)
set(ax, 'XLim',[trec(1),trec(end)])
xlabel('时间/(s)')
ylabel({'地向加速度误差';'/(m/s^2)'})