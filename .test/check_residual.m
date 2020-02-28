% 给定参考位置,检验伪距伪距率残差
% 运行完程序查看resR,resV变量

sv = nCoV.storage.satmeas; %卫星测量数据
% p0 = [45.73104, 126.62482, 200]; %参考位置
% p0 = [45.74565, 126.62615, 180];
p0 = [45.7443, 126.62595, 170];
rp = lla2ecef(p0);
satnav = [rp,[0,0,0],0,0];

chN = length(sv); %卫星数
n = size(sv{1},1); %行数

resR = zeros(n,chN);
resV = zeros(n,chN);

satmeas = zeros(chN,8); %每次的卫星测量数据
for k=1:n
    for i=1:chN
        satmeas(i,:) = sv{i}(k,:);
    end
    [res_rho, res_rhodot] = residual_cal(satmeas, satnav);
    resR(k,:) = res_rho; %伪距残差
    resV(k,:) = res_rhodot; %伪距率残差
end