function satnav = satnavSolve(sv, rp0)
% 卫星导航解算,如果卫星数小于4,返回NaN
% vs:卫星测量信息,[x,y,z,vx,vy,vz,rho,rhodot]
% rp0:接收机大致位置,ecef
% satnav:卫星导航结果,[lat,lon,h, rpx,rpy,rpz, vn,ve,vd, dtr,dtv]

satnav = NaN(1,11);

% 卫星数量小于4,直接返回
if size(sv,1)<4
    return
end

c = 299792458; %光速
rs = sv(:,1:3); %所有卫星位置
vs = sv(:,4:6); %所有卫星速度
R = sv(:,7); %rho,m
V = sv(:,8); %rhodot,m/s
n = size(sv,1); %卫星个数
G = zeros(n,4); %视线矢量矩阵
G(:,4) = -1; %最后一列为-1

% 计算接收机位置
x0 = [rp0, 0]'; %初值
cnt = 0; %迭代计数
while 1
    E = rs - ones(n,1)*x0(1:3)'; %接收机指向卫星位置矢量
    Em = sum(E.*E, 2).^0.5; %取各行的模
    Eu = E ./ (Em*[1,1,1]); %接收机指向卫星视线单位矢量
    G(:,1:3) = Eu;
    S = sum(Eu.*rs, 2); %卫星位置矢量往视线矢量上投影
    x = (G'*G)\G'*(S-R); %最小二乘
    if norm(x-x0)<1e-3 %迭代收敛
        break
    end
    cnt = cnt+1;
    if cnt==10 %最多迭代10次
        break
    end
    x0 = x;
end
rp = x(1:3)';
satnav(1:3) = ecef2lla(rp); %纬经高
satnav(4:6) = rp; %ecef位置
satnav(10) = x(4)/c; %接收机钟差,s

% 计算接收机速度
 E = rs - ones(n,1)*rp;
 Em = sum(E.*E, 2).^0.5;
 Eu = E ./ (Em*[1,1,1]);
 G(:,1:3) = Eu;
 S = sum(Eu.*vs, 2);
 v = (G'*G)\G'*(S-V);
 Cen = dcmecef2ned(satnav(1), satnav(2));
 satnav(7:9) = Cen*v(1:3); %地理系下速度
 satnav(11) = v(4)/c; %接收机钟频差,无量纲

end