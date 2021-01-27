% 两段加速
syms t

%% 水平速度
VhFun = [];
VhFun{1,1} = [0,30];     VhFun{1,2} = 0;
VhFun{2,1} = [30,40];    VhFun{2,2} = 30*(t-30);
VhFun{3,1} = [40,50];    VhFun{3,2} = 300;
VhFun{4,1} = [50,55];    VhFun{4,2} = 300+30*(t-50);
VhFun{5,1} = 55;         VhFun{5,2} = 450;

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
