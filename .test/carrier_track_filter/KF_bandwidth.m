%% 计算不同KF参数下的稳态滤波器带宽
% 考虑的参数是:dt,w,v
% 量测噪声标准差v应该跟随离散时间变化
% 参考check_alpha_beta.m, order2LoopCoefA.m
% 阻尼系数为0.707,说明卡尔曼滤波最优

clear
clc

%% 参数
dt = 0.001;
w = logspace(log10(0.01),log10(100),100); %候选的过程噪声标准差
v = 0.01;
n = length(w); %计算点数

%% 计算
alpha_beta = zeros(n,2); %相位,频率修正系数
K1_K2 = zeros(n,2); %比例积分系数
Bn_zeta = zeros(n,2); %带宽和阻尼
for k=1:n
    lamda = w(k)/v*dt^2;
    r = (4 + lamda - sqrt(8*lamda+lamda^2)) / 4;
    alpha = 1-r^2;
    beta = (2*(2-alpha) - 4*sqrt(1-alpha)) / dt;
    alpha_beta(k,:) = [alpha, beta];
    %--------------------------------------------
    K1 = alpha/dt; %PI控制器中,相位修正由比例项的频率驱动,要除以积分时间
    K2 = beta/dt; %PI控制器中,K2积分才为频率修正,所以也要除以积分时间
    K1_K2(k,:) = [K1, K2];
    %--------------------------------------------
    Wn = sqrt(K2);
    zeta = K1/2/Wn;
    Bn = Wn*(4*zeta^2+1) / (8*zeta);
    Bn_zeta(k,:) = [Bn, zeta];
end

%% 画图
figure('Name','alpha-beta')
subplot(2,1,1)
semilogx(w,alpha_beta(:,1))
ylabel('alpha')
grid on
subplot(2,1,2)
semilogx(w,alpha_beta(:,2))
ylabel('beta')
grid on

figure('Name','K1-K2')
subplot(2,1,1)
semilogx(w,K1_K2(:,1))
ylabel('K1')
grid on
subplot(2,1,2)
semilogx(w,K1_K2(:,2))
ylabel('K2')
grid on

figure('Name','Bn-zeta')
subplot(2,1,1)
semilogx(w,Bn_zeta(:,1))
ylabel('Bn')
grid on
subplot(2,1,2)
semilogx(w,Bn_zeta(:,2))
ylabel('zeta')
grid on