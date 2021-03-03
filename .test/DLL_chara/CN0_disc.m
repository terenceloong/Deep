% 不同积分时间下码鉴相器噪声标准差与载噪比的关系曲线
% 给出拟合系数:A,a
% CN0--log10_sigma_disc曲线是直线,对于不同的积分时间斜率相等,常数项不等
% log10_sigma_disc = A*CN0 + B(Tms)
% 常数项与毫秒积分时间的拟合函数为: B(Tms) = -log10(a*Tms)/2
% 10^(-B*2)是一条过原点的直线
% 系数: A=-0.05, a=0.008
% 码鉴相器噪声标准差计算公式: 10^(-0.05*CN0) / sqrt(0.008*Tms)

%% 设置
d = 0.3; %码鉴相器间隔,码片
CN0_table = 35:0.5:60; %载噪比表
T_table = [1,2,4,5,10,20] * 0.001; %积分时间表
n = 10000; %计算数据点数

CN0_N = length(CN0_table); %载噪比个数
T_N = length(T_table); %积分时间个数

result = zeros(CN0_N,T_N); %统计结果,每一行是一个载噪比,每一列是一个积分时间

%% 计算
for m=1:T_N %遍历积分时间
    T = T_table(m); %积分时间
    for w=1:CN0_N %遍历载噪比
        CN0 = CN0_table(w); %载噪比
        A = sqrt(2*T*10^(CN0/10)); %积分幅值
        noiseE = (randn(1,n) + randn(1,n)*1j) / sqrt(2); %超前路复噪声
        noiseL = (randn(1,n) + randn(1,n)*1j) / sqrt(2); %滞后路复噪声
        SE = abs(A*(1-d)+noiseE); %超前路幅值
        SL = abs(A*(1-d)+noiseL); %滞后路幅值
        e = (1-d) * (SE-SL) ./ (SE+SL);
%         SE = abs(A*(1-1.5*d)+noiseE); %超前路幅值
%         SL = abs(A*(1-1.5*d)+noiseL); %滞后路幅值
%         e = (11/30) * (SE-SL) ./ (SE+SL) / 2;
        result(w,m) = std(e);
    end
end

%% 画图
figure
for k=1:T_N
    semilogy(CN0_table, result(:,k)) %取log10是线性
    hold on
end
grid on
xlabel('载噪比 (dB·Hz)')
ylabel('码鉴相器噪声标准差 (码片)')
title('不同积分时间下码鉴相器噪声标准差与载噪比的关系曲线')
legend('1ms','2ms','4ms','5ms','10ms','20ms')

%% 拟合CN0--log10_sigma_disc曲线
result_log10 = log10(result);
coef = zeros(T_N,2); %每行是一个积分时间
for k=1:T_N
    coef(k,:) = polyfit(CN0_table, result_log10(:,k), 1); %一次多项式拟合
end
A = mean(coef(:,1)); %斜率

%% 拟合Tms--B曲线
Tms_table = T_table * 1000; %积分时间变成ms
B_Tms = coef(:,2)'; %取常数项B

Y = 10.^(-B_Tms*2); %对B_Bn做变换
a = (Tms_table*Y') / (Tms_table*Tms_table'); %最小二乘求斜率

figure
plot(Tms_table, Y, '.', 'MarkerSize',12)
hold on
grid on
plot(Tms_table, a*Tms_table)
xlabel('积分时间 (ms)')
ylabel('10^-^B^*^2')
title('B变换后的拟合结果')
legend('data', 'fit', 'Location','NorthWest')

figure
plot(Tms_table, B_Tms, '.', 'MarkerSize',12)
hold on
grid on
x = Tms_table(1):0.2:Tms_table(end); %点取密一点
plot(x, -log10(a*x)/2)
xlabel('积分时间 (ms)')
ylabel('B')
title('B变换前的拟合结果')
legend('data', 'fit',  'Location','NorthEast')

%% 显示结果
disp(['A=',num2str(A),', a=',num2str(a)])