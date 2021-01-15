% 测试窄带宽带功率比值法(NWPR)
% 相同计算点数情况下,NWPR比MM计算噪声小
% NWPR可以计算较低的载噪比,A/sigma可以小于3

CN0 = 45; %载噪比
T = 0.001; %积分时间
N = 20; %小段点数
M = 20; %平均点数

n = 1000; %计算次数
result = zeros(n,1);

A = sqrt(2*T*10^(CN0/10)); %积分幅值
N_W = zeros(1,M);
for k=1:n
    for m=1:M
        IP = A + randn(1,N); %I路积分结果
        QP = randn(1,N); %Q路积分结果
        WBP = sum(IP.^2 + QP.^2); %宽带功率,先平方再求和
        NBP = sum(IP)^2 + sum(QP)^2; %窄带功率先求和再平方
        N_W(m) = NBP / WBP;
    end
    Z = mean(N_W);
    S = (Z-1) / (N-Z) / T;
    if S>10
        result(k) = 10*log10(S);
    else
        result(k) = 10;
    end
end

%% 画散点分布
figure
plot(randn(1,n)+A,randn(1,n), 'LineStyle','none', 'Marker','.')
hold on
plot(randn(1,n)-A,randn(1,n), 'LineStyle','none', 'Marker','.')
grid on
axis equal
set(gca, 'Xlim', [-5-A, 5+A])
set(gca, 'Ylim', [-5-A, 5+A])

%% 画计算结果
figure
plot(result)
hold on
grid on
plot([1,n], [CN0,CN0], 'LineWidth',2)
legend('计算值','理论值')