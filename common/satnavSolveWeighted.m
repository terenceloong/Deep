function satnav = satnavSolveWeighted(sv, rp0)
% 卫星导航解算,如果卫星数小于4,返回NaN
% vs:卫星测量信息,[x,y,z,vx,vy,vz,rho,rhodot,R_rho,R_rhodot]
% rp0:接收机大致位置,ecef
% satnav:卫星导航结果,[lat,lon,h,x,y,z,vn,ve,vd,vx,vy,vz,dtr,dtv]

satnav = NaN(1,14);

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

% 检验几何精度因子
E = rs - ones(n,1)*rp0;
Em = vecnorm(E,2,2);
Eu = E ./ (Em*[1,1,1]);
G(:,1:3) = Eu;
D = inv(G'*G);
Ddiag = diag(D);
PDOP = sqrt(Ddiag(1)+Ddiag(2)+Ddiag(3));
if PDOP>10 %几何精度因子大就不算了
    return
end

% 权值矩阵
Wr = diag(sv(:,9).^-1); %位置权值
Wv = diag(sv(:,10).^-1); %速度权值

% 计算接收机位置
x0 = [rp0, 0]'; %初值
cnt = 0; %迭代计数
while 1
    E = rs - ones(n,1)*x0(1:3)'; %接收机指向卫星位置矢量
    Em = vecnorm(E,2,2); %取各行的模
    Eu = E ./ (Em*[1,1,1]); %接收机指向卫星视线单位矢量
    G(:,1:3) = Eu;
    S = sum(Eu.*rs,2); %卫星位置矢量往视线矢量上投影
    x = (G'*Wr*G)\G'*Wr*(S-R); %最小二乘
    if norm(x-x0)<1e-3 %迭代收敛
        break
    end
    cnt = cnt+1;
    if cnt==10 %最多迭代10次
        break
    end
    x0 = x;
end
rp = x(1:3)'; %行向量
satnav(1:3) = ecef2lla(rp); %纬经高
satnav(4:6) = rp; %ecef位置
satnav(13) = x(4)/c; %接收机钟差,s

% 计算接收机速度
E = rs - ones(n,1)*rp;
Em = vecnorm(E,2,2);
Eu = E ./ (Em*[1,1,1]);
G(:,1:3) = Eu;
S = sum(Eu.*vs,2);
cm = 1 + S/c; %光速修正
G(:,4) = -cm;
v = (G'*Wv*G)\G'*Wv*(S-V.*cm);
% v = (G'*Wv*G)\G'*Wv*(S-V);
Cen = dcmecef2ned(satnav(1), satnav(2));
satnav(7:9) = Cen*v(1:3); %地理系下速度
satnav(10:12) = v(1:3); %ecef系下速度
satnav(14) = v(4)/c; %接收机钟频差,无量纲

end