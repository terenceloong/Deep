%% 画在线卫星导航结果
figure('Name','位置')
subplot(3,1,1)
plot(pos(:,1))
grid on
subplot(3,1,2)
plot(pos(:,2))
grid on
subplot(3,1,3)
plot(pos(:,3))
grid on

figure('Name','速度')
subplot(3,1,1)
plot(vel(:,1))
grid on
subplot(3,1,2)
plot(vel(:,2))
grid on
subplot(3,1,3)
plot(vel(:,3))
grid on

figure('Name','时钟')
subplot(2,1,1)
plot(clk(:,1))
grid on
subplot(2,1,2)
plot(clk(:,2))
grid on

%% 画在线滤波结果
figure('Name','位置')
subplot(3,1,1)
plot(pos(:,1))
hold on
grid on
plot(posF(:,1))
subplot(3,1,2)
plot(pos(:,2))
hold on
grid on
plot(posF(:,2))
subplot(3,1,3)
plot(pos(:,3))
hold on
grid on
plot(posF(:,3))

figure('Name','速度')
subplot(3,1,1)
plot(vel(:,1))
hold on
grid on
plot(velF(:,1))
subplot(3,1,2)
plot(vel(:,2))
hold on
grid on
plot(velF(:,2))
subplot(3,1,3)
plot(vel(:,3))
hold on
grid on
plot(velF(:,3))

figure('Name','加速度')
subplot(3,1,1)
plot(accF(:,1))
grid on
subplot(3,1,2)
plot(accF(:,2))
grid on
subplot(3,1,3)
plot(accF(:,3))
grid on

figure('Name','时钟')
subplot(2,1,1)
plot(clk(:,1))
hold on
grid on
plot(clkF(:,1))
plot(clk(:,1)-clkF(:,1))
subplot(2,1,2)
plot(clk(:,2))
hold on
grid on
plot(clkF(:,2))

%% 比较离线卫星导航解算
figure('Name','位置')
subplot(3,1,1)
plot(pos(:,1))
hold on
grid on
plot(satnav(:,1))
subplot(3,1,2)
plot(pos(:,2))
hold on
grid on
plot(satnav(:,2))
subplot(3,1,3)
plot(pos(:,3))
hold on
grid on
plot(satnav(:,3))

figure('Name','速度')
subplot(3,1,1)
plot(vel(:,1))
hold on
grid on
plot(satnav(:,7))
subplot(3,1,2)
plot(vel(:,2))
hold on
grid on
plot(satnav(:,8))
subplot(3,1,3)
plot(vel(:,3))
hold on
grid on
plot(satnav(:,9))

figure('Name','时钟')
subplot(2,1,1)
plot(clk(:,1))
hold on
grid on
plot(satnav(:,13)*1000)
plot(satnav(:,13)*1000-clk(:,1))
subplot(2,1,2)
plot(clk(:,2))
hold on
grid on
plot(satnav(:,14)*1e6)

%% 画离线滤波结果
figure('Name','位置')
subplot(3,1,1)
plot(satnav(:,1))
hold on
grid on
plot(filternav(:,1))
subplot(3,1,2)
plot(satnav(:,2))
hold on
grid on
plot(filternav(:,2))
subplot(3,1,3)
plot(satnav(:,3))
hold on
grid on
plot(filternav(:,3))

figure('Name','速度')
subplot(3,1,1)
plot(satnav(:,7))
hold on
grid on
plot(filternav(:,4))
subplot(3,1,2)
plot(satnav(:,8))
hold on
grid on
plot(filternav(:,5))
subplot(3,1,3)
plot(satnav(:,9))
hold on
grid on
plot(filternav(:,6))

figure('Name','加速度')
subplot(3,1,1)
plot(filternav(:,7))
grid on
subplot(3,1,2)
plot(filternav(:,8))
grid on
subplot(3,1,3)
plot(filternav(:,9))
grid on

figure('Name','时钟')
subplot(2,1,1)
plot(satnav(:,13))
hold on
grid on
plot(filternav(:,10))
plot(filternav(:,10)-satnav(:,13))
subplot(2,1,2)
plot(satnav(:,14))
hold on
grid on
plot(filternav(:,11))