% 静止滚转
syms t

%% 水平速度
VhFun = [];
VhFun{1,1} = 0;          VhFun{1,2} = 0;

%% 速度方向
VyFun = [];
VyFun{1,1} = 0;          VyFun{1,2} = 0;

%% 天向速度
VuFun = [];
VuFun{1,1} = 0;          VuFun{1,2} = 0;

%% 航向角
AyFun = [];
AyFun{1,1} = 0;          AyFun{1,2} = 0;

%% 俯仰角
ApFun = [];
ApFun{1,1} = 0;          ApFun{1,2} = 0;

%% 滚转角
ArFun = [];
ArFun{1,1} = [0,30];     ArFun{1,2} = 0;
ArFun{2,1} = [30,48];    ArFun{2,2} = 60*(t-30);
ArFun{3,1} = 48;         ArFun{3,2} = 1080;
