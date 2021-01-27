% 加速度连续
syms t

%% 水平速度
VhFun = [];
VhFun{1,1} = [0,30];     VhFun{1,2} = 0;
VhFun{2,1} = [30,33];    VhFun{2,2} = 0.5*10*(t-30)^2;
VhFun{3,1} = [33,43];    VhFun{3,2} = 45+30*(t-33);
VhFun{4,1} = [43,46];    VhFun{4,2} = 345+30*(t-43)-0.5*10*(t-43)^2;
VhFun{5,1} = 46;         VhFun{5,2} = 390;

%% 速度方向
VyFun = [];
VyFun{1,1} = 0;          VyFun{1,2} = 90;

%% 天向速度
VuFun = [];
VuFun{1,1} = 0;          VuFun{1,2} = 0;

%% 航向角
AyFun = [];
AyFun{1,1} = 0;          AyFun{1,2} = 90;

%% 俯仰角
ApFun = [];
ApFun{1,1} = 0;          ApFun{1,2} = 0;

%% 滚转角
ArFun = [];
ArFun{1,1} = 0;          ArFun{1,2} = 0;
