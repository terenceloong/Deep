% 测试二阶PLL的跟踪特性
% 用于验证环路仿真得对不对
% 鉴相器输出,载波频率输出应该能跟接收机处理仿真中频数据对上

%% 指定环路带宽,积分时间,信号载噪比
Bn = 25; %环路带宽
T = 0.001; %积分时间
CN0 = 48; %载噪比
n = 100000; %计算数据点数

%% 计算
[Eout, Fout, Pout] = PLL2_cal(Bn, T, CN0, n);

%% 画图
figure
plot(Eout)
grid on
title('载波鉴相器输出')
figure
plot(Fout)
grid on
title('载波频率输出')
figure
plot(Pout)
grid on
title('载波相位输出')