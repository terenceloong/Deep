%% 给定参考位置,检验伪距伪距率残差
% 运行完程序查看resR,resV变量.
% 应该在无时钟反馈时进行

sv = nCoV.storage.satmeas; %卫星测量数据
p0 = [45.73104, 126.62482, 200]; %参考位置
rp = lla2ecef(p0);
satnav = [rp,[0,0,0],0,0];

svN = length(sv); %卫星数
n = size(sv{1},1); %数据点数

resR = zeros(n,svN);
resV = zeros(n,svN);

satmeas = zeros(svN,8); %每次的卫星测量数据
for k=1:n
    for i=1:svN
        satmeas(i,:) = sv{i}(k,:);
    end
    [res_rho, res_rhodot] = residual_cal(satmeas, satnav);
    resR(k,:) = res_rho; %伪距残差
    resV(k,:) = res_rhodot; %伪距率残差
end