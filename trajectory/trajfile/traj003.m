% 6个量都变的轨迹
syms t

%% 水平速度
VhFun = [];
VhFun{1,1} = [0,30];     VhFun{1,2} = 0;
VhFun{2,1} = [30,35];    VhFun{2,2} = 2*(t-30);
VhFun{3,1} = [35,45];    VhFun{3,2} = 10;
VhFun{4,1} = [45,50];    VhFun{4,2} = 10-2*(t-45);
VhFun{5,1} = 50;         VhFun{5,2} = 0;

%% 速度方向
VyFun = [];
VyFun{1,1} = [0,35];     VyFun{1,2} = 45;
VyFun{2,1} = [35,45];    VyFun{2,2} = 45+9*(t-35);
VyFun{3,1} = 45;         VyFun{3,2} = 135;

%% 天向速度
VuFun = [];
VuFun{1,1} = [0,30];     VuFun{1,2} = 0;
VuFun{2,1} = [30,35];    VuFun{2,2} = 2*(t-30);
VuFun{3,1} = [35,45];    VuFun{3,2} = 10;
VuFun{4,1} = [45,50];    VuFun{4,2} = 10-2*(t-45);
VuFun{5,1} = 50;         VuFun{5,2} = 0;

%% 航向角
AyFun = [];
AyFun{1,1} = [0,35];     AyFun{1,2} = 45;
AyFun{2,1} = [35,45];    AyFun{2,2} = 45+9*(t-35);
AyFun{3,1} = 45;         AyFun{3,2} = 135;

%% 俯仰角
ApFun = [];
ApFun{1,1} = [0,40];     ApFun{1,2} = 0;
ApFun{2,1} = [40,45];    ApFun{2,2} = 4*(t-40);
ApFun{3,1} = [45,50];    ApFun{3,2} = 20-4*(t-45);
ApFun{4,1} = 50;         ApFun{4,2} = 0;

%% 滚转角
ArFun = [];
ArFun{1,1} = [0,45];     ArFun{1,2} = 0;
ArFun{2,1} = [45,50];    ArFun{2,2} = 4*(t-45);
ArFun{3,1} = [50,55];    ArFun{3,2} = 20-4*(t-50);
ArFun{4,1} = 55;         ArFun{4,2} = 0;
