% 导航结果与仿真器基准值比较

trec = time*[1;1e-3;1e-6] - t0; %接收时间序列,从0开始
tsim = motionSim(:,1) - t0; %基准值时间序列,从0开始

%% 画位置
figure
subplot(3,1,1)
plot(trec,posF(:,1))
hold on
plot(tsim,motionSim(:,2))
ax = gca;
set(ax, 'XLim',[trec(1),trec(end)])
grid on

subplot(3,1,2)
plot(trec,posF(:,2))
hold on
plot(tsim,motionSim(:,3))
ax = gca;
set(ax, 'XLim',[trec(1),trec(end)])
grid on

subplot(3,1,3)
plot(trec,posF(:,3))
hold on
plot(tsim,motionSim(:,4))
ax = gca;
set(ax, 'XLim',[trec(1),trec(end)])
grid on

%% 画速度
figure
subplot(3,1,1)
plot(trec,velF(:,1))
hold on
plot(tsim,motionSim(:,5))
ax = gca;
set(ax, 'XLim',[trec(1),trec(end)])
grid on

subplot(3,1,2)
plot(trec,velF(:,2))
hold on
plot(tsim,motionSim(:,6))
ax = gca;
set(ax, 'XLim',[trec(1),trec(end)])
grid on

subplot(3,1,3)
plot(trec,velF(:,3))
hold on
plot(tsim,motionSim(:,7))
ax = gca;
set(ax, 'XLim',[trec(1),trec(end)])
grid on

%% 画加速度
figure
subplot(3,1,1)
plot(trec,accF(:,1))
hold on
plot(tsim,motionSim(:,8))
ax = gca;
set(ax, 'XLim',[trec(1),trec(end)])
grid on

subplot(3,1,2)
plot(trec,accF(:,2))
hold on
plot(tsim,motionSim(:,9))
ax = gca;
set(ax, 'XLim',[trec(1),trec(end)])
grid on

subplot(3,1,3)
plot(trec,accF(:,3))
hold on
plot(tsim,motionSim(:,10))
ax = gca;
set(ax, 'XLim',[trec(1),trec(end)])
grid on