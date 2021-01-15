% 二阶PLL不同积分时间下载波频率标准差与载噪比的关系曲线(固定环路带宽)
% 载噪比高时,不同积分时间的曲线重合.说明对于指定环路带宽,积分时间不影响载波频率跟踪精度
% 载噪比低时,积分时间短,载波频率标准差大.说明短积分时间跟踪弱信号的能力差
% 积分时间越长得到的曲线越平

%% 设置
Bn = 15; %带宽
CN0_table = 24:0.5:60; %载噪比表
T_table = [1,2,4,5,10,20] * 0.001; %积分时间表
n = 100000; %计算数据点数

CN0_N = length(CN0_table); %载噪比个数
T_N = length(T_table); %积分时间个数

result = zeros(CN0_N,T_N); %统计结果,每一行是一个载噪比,每一列是一个积分时间

%% 计算
for m=1:T_N %遍历积分时间
    T = T_table(m); %积分时间
    for w=1:CN0_N %遍历载噪比
        CN0 = CN0_table(w); %载噪比
        [~, Fout, ~] = PLL2_cal(Bn, T, CN0, n);
        result(w,m) = std(Fout);
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
ylabel('载波频率标准差 (Hz)')
title('不同积分时间下载波频率标准差与载噪比的关系曲线')
legend('1ms','2ms','4ms','5ms','10ms','20ms')