% 8字型轨迹
% <Global Positioning Systems, Inertial Navigation, and Integration> P399

%% 参数
L = 5000; %轨迹长度
V = 100; %平均速度
S = L/14.94375529901562;
w = 2*pi*V/L;

T = L/V; %总时间
t = (0:0.001:1)*T;

%% 位置
x = 3*S*sin(w*t); %长轴方向
y = 2*S*sin(w*t) .* cos(w*t);

figure
plot(x,y)
axis equal
grid on

%% 速度
vx = 3*S*w*cos(w*t);
vy = 2*S*w*(cos(w*t).^2-sin(w*t).^2);
figure
subplot(3,1,1)
plot(t,vx)
grid on
subplot(3,1,2)
plot(t,vy)
grid on
subplot(3,1,3)
plot(t,sqrt(vx.^2+vy.^2)) %速度绝对值
grid on

%% 加速度
ax = -3*S*w^2*sin(w*t);
ay = -8*S*w^2*sin(w*t) .* cos(w*t);
figure
subplot(3,1,1)
plot(t,ax)
grid on
subplot(3,1,2)
plot(t,ay)
grid on
subplot(3,1,3)
plot(t,sqrt(ax.^2+ay.^2)) %加速度绝对值
grid on