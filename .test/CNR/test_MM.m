% 测试矩方法(MM)
% GNSS Solutions: Carrier-to-Noise Algorithms
% 高载噪比时,改变积分时间不影响计算噪声,一次计算用多少点影响计算噪声
% 低载噪比时需要提高积分时间,否则可能算不出数
% A/sigma>3时才能得到较好的计算结果

CN0 = 45; %载噪比
T = 0.001; %积分时间
N = 400; %一次用多少点

n = 1000; %计算次数
result = zeros(n,1);

A = sqrt(2*T*10^(CN0/10)); %积分幅值
for k=1:n
    IP = A + randn(1,N); %I路积分结果
    QP = randn(1,N); %Q路积分结果
    M2 = sum(IP.^2+QP.^2)/N; %二阶矩
    M4 = sum((IP.^2+QP.^2).^2)/N; %四阶矩
    Pd = sqrt(2*M2^2 - M4); %信号功率
    Pn = M2 - Pd; %噪声功率
    lamda = Pd / Pn; %功率比
    result(k) = 10*log10(lamda/T);
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