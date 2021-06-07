% 计算导航结果与仿真器基准值的误差

trec = time*[1;1e-3;1e-6] - t0; %接收时间序列,从0开始
tsim = motionSim(:,1) - t0; %基准值时间序列,从0开始

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

dP1 = posF(:,1) - P1(trec);
dP2 = posF(:,2) - P2(trec);
dP3 = posF(:,3) - P3(trec);
dV1 = velF(:,1) - V1(trec);
dV2 = velF(:,2) - V2(trec);
dV3 = velF(:,3) - V3(trec);
dA1 = accF(:,1) - A1(trec);
dA2 = accF(:,2) - A2(trec);
dA3 = accF(:,3) - A3(trec);

%% 画位置误差
figure
subplot(3,1,1)
plot(trec,dP1)
ax = gca;
set(ax, 'XLim',[trec(1),trec(end)])
grid on

subplot(3,1,2)
plot(trec,dP2)
ax = gca;
set(ax, 'XLim',[trec(1),trec(end)])
grid on

subplot(3,1,3)
plot(trec,dP3)
ax = gca;
set(ax, 'XLim',[trec(1),trec(end)])
grid on

%% 画速度误差
figure
subplot(3,1,1)
plot(trec,dV1)
ax = gca;
set(ax, 'XLim',[trec(1),trec(end)])
grid on

subplot(3,1,2)
plot(trec,dV2)
ax = gca;
set(ax, 'XLim',[trec(1),trec(end)])
grid on

subplot(3,1,3)
plot(trec,dV3)
ax = gca;
set(ax, 'XLim',[trec(1),trec(end)])
grid on

%% 画加速度误差
figure
subplot(3,1,1)
plot(trec,dA1)
ax = gca;
set(ax, 'XLim',[trec(1),trec(end)])
grid on

subplot(3,1,2)
plot(trec,dA2)
ax = gca;
set(ax, 'XLim',[trec(1),trec(end)])
grid on

subplot(3,1,3)
plot(trec,dA3)
ax = gca;
set(ax, 'XLim',[trec(1),trec(end)])
grid on