% 二阶DLL不同环路带宽下码相位标准差与载噪比的关系曲线(固定积分时间)
% 给出拟合系数:A,a
% CN0--log10_sigma_Pcode曲线是直线,对于不同的环路带宽斜率相等,常数项不等
% log10_sigma_Pcode = A*CN0 + B(Bn)
% 常数项与环路带宽的拟合函数为: B(Bn) = log10(a*Bn)/2
% 10^(B*2)是一条过原点的直线
% 系数: A=-0.05, a=0.264
% 码相位标准差计算公式: 10^(-0.05*CN0) * sqrt(0.264*Bn)
% 伪距噪声标准差计算公式: 10^(-0.05*CN0) * sqrt(0.264*Bn) * 300
% 伪距噪声方差计算公式: 10^(-0.1*CN0) * (0.264*Bn) * 9e4
% 与处理仿真中频数据比较时,接收机应该关闭时钟修正,否则各通道的伪距误差相关

%% 设置
Bn_table = 0.2:0.2:2; %环路带宽表
CN0_table = 28:0.5:60; %载噪比表
T = 0.02; %积分时间(不同积分时间曲线趋势一样,积分时间长噪声小)
n = 100000; %计算数据点数

Bn_N = length(Bn_table); %环路带宽个数
CN0_N = length(CN0_table); %载噪比个数

result = zeros(CN0_N,Bn_N); %统计结果,每一行是一个载噪比,每一列是一个带宽

%% 计算
for m=1:Bn_N %遍历带宽
    Bn = Bn_table(m); %带宽
    for w=1:CN0_N %遍历载噪比
        CN0 = CN0_table(w); %载噪比
        [~, ~, Pout] = DLL2_cal(Bn, T, CN0, n);
        result(w,m) = std(Pout);
    end
end

%% 画图
figure
for k=1:Bn_N
    semilogy(CN0_table, result(:,k))
    hold on
end
grid on
xlabel('载噪比 (dB·Hz)')
ylabel('码相位标准差 (码片)')
title('不同环路带宽下码相位标准差与载噪比的关系曲线')

figure
for k=1:Bn_N
    semilogy(CN0_table, result(:,k)*300)
    hold on
end
grid on
xlabel('载噪比 (dB·Hz)')
ylabel('伪距噪声标准差 (m)')
title('不同环路带宽下伪距噪声标准差与载噪比的关系曲线')

%% 拟合CN0--log10_sigma_Pcode曲线
result_log10 = log10(result);
coef = zeros(Bn_N,2); %每行是一个带宽
for k=1:Bn_N
    coef(k,:) = polyfit(CN0_table, result_log10(:,k), 1); %一次多项式拟合
end
A = mean(coef(:,1)); %斜率

%% 拟合Bn--B曲线
B_Bn = coef(:,2)'; %取常数项B

Y = 10.^(B_Bn*2); %对B_Bn做变换
a = (Bn_table*Y') / (Bn_table*Bn_table'); %最小二乘求斜率

figure
plot(Bn_table, Y, '.', 'MarkerSize',12)
hold on
grid on
plot(Bn_table, a*Bn_table)
xlabel('环路带宽 (Hz)')
ylabel('10^B^*^2')
title('B变换后的拟合结果')
legend('data', 'fit', 'Location','NorthWest')

figure
plot(Bn_table, B_Bn, '.', 'MarkerSize',12)
hold on
grid on
x = Bn_table(1):0.05:Bn_table(end); %点取密一点
plot(x, log10(a*x)/2)
xlabel('环路带宽 (Hz)')
ylabel('B')
title('B变换前的拟合结果')
legend('data', 'fit',  'Location','NorthWest')

%% 显示结果
disp(['A=',num2str(A),', a=',num2str(a)])