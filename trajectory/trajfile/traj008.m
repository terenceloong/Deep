% 模拟手晃
syms t

%% 水平速度
VhFun = [];
VhFun{1,1} = [0,30];     VhFun{1,2} = 0;
VhFun{2,1} = [30,90];    VhFun{2,2} = 2*(pi*pi/3)*sin(2*pi/3*(t-30));
VhFun{3,1} = 90;         VhFun{3,2} = 0;

%% 速度方向
VyFun = [];
VyFun{1,1} = [0,30];     VyFun{1,2} = 0;
VyFun{2,1} = [30,90];    VyFun{2,2} = 90-90*cos(2*pi/3*(t-30));
VyFun{3,1} = 90;         VyFun{3,2} = 0;

%% 天向速度
VuFun = [];
VuFun{1,1} = 0;          VuFun{1,2} = 0;

%% 航向角
AyFun = [];
AyFun{1,1} = [0,30];     AyFun{1,2} = -90;
AyFun{2,1} = [30,90];    AyFun{2,2} = -90*cos(2*pi/3*(t-30));
AyFun{3,1} = 90;         AyFun{3,2} = -90;

%% 俯仰角
ApFun = [];
ApFun{1,1} = 0;          ApFun{1,2} = 0;

%% 滚转角
ArFun = [];
ArFun{1,1} = 0;          ArFun{1,2} = 0;
