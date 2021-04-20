%% 测试卫星导航滤波器(使用数据)

%% 配置参数
para.dt = nCoV.dtpos / 1000;
para.p0 = nCoV.storage.pos(1,1:3);
para.v0 = [0,0,0];
para.P0_pos = 5; %m
para.P0_vel = 1; %m/s
para.P0_acc = 1; %m/s^2
para.P0_dtr = 2e-8; %s
para.P0_dtv = 3e-9; %s/s
para.Q_pos = 0;
para.Q_vel = 0;
para.Q_acc = 100;
para.Q_dtr = 0;
para.Q_dtv = 1e-9;
NF = filter_sat(para);

svN = nCoV.chN;
sv = zeros(svN,10);
n = size(nCoV.storage.ta,1);

%% 输出结果
output.satnav = zeros(n,14);
output.pos = zeros(n,3);
output.vel = zeros(n,3);
output.clk = zeros(n,2);
output.P = zeros(n,11);

%% 计算
for k=1:n
    % 卫星量测
    for m=1:svN
        sv(m,:) = nCoV.storage.satmeas{m}(k,:);
    end
    indexP = (nCoV.storage.svsel(k,:)>=1)';
    indexV = (nCoV.storage.svsel(k,:)==2)';
    
    % 卫星导航解算
    satnav = satnavSolveWeighted(sv(indexV,:), NF.rp);
    
    % 导航滤波
    NF.run(sv, indexP, indexV);
    
    % 存储结果
    output.satnav(k,:) = satnav;
    output.pos(k,:) = NF.pos;
    output.vel(k,:) = NF.vel;
    output.clk(k,:) = [NF.dtr, NF.dtv];
    output.P(k,:) = sqrt(diag(NF.P));
end

%% 画位置输出
t = nCoV.storage.ta - nCoV.storage.ta(1);
t = t + nCoV.Tms/1000 - t(end);
figure('Name','位置')
for k=1:3
    subplot(3,1,k)
    plot(t,[output.satnav(:,k),output.pos(:,k)])
    grid on
end

%% 画速度输出
figure('Name','速度')
for k=1:3
    subplot(3,1,k)
    plot(t,[output.satnav(:,k+6),output.vel(:,k)])
    grid on
end

%% 画钟差钟频差
figure('Name','钟差钟频差')
subplot(2,1,1)
plot(t,[output.satnav(:,13),output.clk(:,1)])
grid on
subplot(2,1,2)
plot(t,[output.satnav(:,14),output.clk(:,2)])
grid on