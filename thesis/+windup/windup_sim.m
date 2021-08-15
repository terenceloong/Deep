% 计算天线旋转时相位缠绕效应引起的载波相位误差和频率误差
clear
clc

%% 加载星历
load('~temp\ephemeris\20200727_111614.mat')
ephe = ephemeris.GPS_ephe;
svList = [1,3,6,17,19,22,28]; %可见卫星列表
svN = length(svList);

%% 位置时间信息
p0 = [45.7364, 126.70775, 165];
rp = lla2ecef(p0);
Cen = dcmecef2ned(p0(1), p0(2));
t0 = 98192;

%% 计算卫星位置
sv = zeros(svN,3);
for k=1:svN
    PRN = svList(k);
    rsvs = LNAV.rsvs_ephe(ephe(PRN,10:25), t0);
    sv(k,:) = rsvs(1:3);
end

%% 计算太阳位置
utc = [2020,7,27,3,16,14]; %跟上面的t0对上
rt = planetEphemeris(juliandate(utc),'Earth','Sun')*1000; %太阳eci位置
Cie = dcmeci2ecef('IAU-2000/2006',utc);
rt = rt*Cie'; %太阳ecef位置
% 算一下太阳高度角方位角,看看算的对不对
rpt = rt - rp;
rptu = rpt / norm(rpt);
rptu_n = rptu*Cen';
ele = -asind(rptu_n(3)); %太阳高度角
azi = atan2d(rptu_n(2),rptu_n(1)); %太阳方位角

%% 计算
n = 180; %每2度一算
er = [0.1, 0.1, 1]; %旋转轴方向
eru = er / norm(er); %单位矢量
omega = 100; %旋转角速度,deg/s
wb = eru * omega/180*pi; %体系下的角速度矢量,rads
phi = zeros(n,svN); %周
phidot = zeros(n,svN); %Hz
att = zeros(n,3);
for k=1:n
    for m=1:svN
        % 卫星天线姿态
        rs = sv(m,:);
        cs = -rs / norm(rs); %卫星指向地心的单位矢量,z'轴
        rst = rt - rs; %卫星指向太阳矢量
        bs = cross(cs,rst);
        bs = bs / norm(bs); %y'轴
        as = cross(bs,cs); %x'轴
        % 视线单位矢量
        rsp = rp - rs; %卫星指向接收机
        rspu = rsp / norm(rsp);
        % 接收机天线姿态
        theta_2 = (k-1)/180*pi; %rad
        q = [cos(theta_2), eru*sin(theta_2)];
        Cnb = quat2dcm(q);
        Ceb = Cnb*Cen;
        [r1,r2,r3] = quat2angle(q);
        att(k,:) = [r1,r2,r3]/pi*180;
        % 计算相位缠绕效应
        [phi(k,m), phidot(k,m)] = windup(as, bs, rspu, wb, Ceb);
        % 删除在天线方向图以下的
        rpsu = -rspu; %接收机指向卫星
        rpsu_b = rpsu*Ceb'; %转到体系下
        if(-asind(rpsu_b(3))<5)
            phi(k,m) = NaN;
            phidot(k,m) = NaN;
        end
    end
end
% 将相位变连续
for k=1:svN
    phi(:,k) = attContinuous(phi(:,k)*360)/360;
end
% 检查频率算得对不对
phidiff = diff(phi,1,1) / (2/omega); %与phidot比较
phidot = round(phidot,8);

%% 画图
dt = 2/omega;
t = (0:n-1)*dt;

figure
plot(t,phi)
grid on

figure
plot(t,phidot, 'LineWidth',1.5)
grid on
ax = gca;
set(ax, 'FontSize',12)
set(ax, 'XLim',[0,n*dt])
xlabel('时间/(s)')
ylabel('频率误差/(Hz)')
legend('1','3','6','17','19','22','28')

figure
plot(t,phidot*0.1903)
grid on 