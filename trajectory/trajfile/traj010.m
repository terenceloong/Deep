% 8字型轨迹
syms t

L = 10000; %轨迹长度
V = 200; %平均速度
h = 500; %高度变化
S = L/14.94375529901562;
w = 2*pi*V/L;

%% 水平速度
VhFun = [];
VhFun{1,1} = 0;          VhFun{1,2} = sqrt((3*S*w*cos(w*t))^2+(2*S*w*(cos(w*t)^2-sin(w*t)^2))^2);

%% 速度方向
VyFun = [];
VyFun{1,1} = 0;          VyFun{1,2} = atan2d(2*S*w*(cos(w*t)^2-sin(w*t)^2), 3*S*w*cos(w*t));

%% 天向速度
VuFun = [];
VuFun{1,1} = 0;          VuFun{1,2} = 0.5*h*w*sin(w*t);

%% 航向角
AyFun = [];
AyFun{1,1} = 0;          AyFun{1,2} = atan2d(2*S*w*(cos(w*t)^2-sin(w*t)^2), 3*S*w*cos(w*t));

%% 俯仰角
ApFun = [];
ApFun{1,1} = 0;          ApFun{1,2} = 0;

%% 滚转角
ArFun = [];
ArFun{1,1} = 0;          ArFun{1,2} = 0;
