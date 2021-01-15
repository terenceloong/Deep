classdef filter_single < handle
% 单天线导航滤波器,位置速度都是惯导的
    
    properties
        motion  %运动状态检测
        pos     %位置,纬经高
        vel     %速度,地理系
        att     %姿态
        rp      %位置,ecef
        vp      %速度,ecef
        quat    %姿态四元数
        dtr     %钟差,s
        dtv     %钟频差,s/s
        bias    %零偏,[gyro,acc],[deg/s,g]
        T       %更新周期
        Rm      %子午圈半径
        Rn      %卯酉圈半径
        g       %重力加速度,m/s^2
        dlatdn  %纬度对北向位移的导数
        dlonde  %经度对东向位移的导数
        P       %P阵
        Q       %Q阵
        Rwb     %陀螺仪输出噪声方差
        wbDelay %延迟的角速度输出
        arm     %杆臂矢量,体系下IMU指向天线
        wdot    %角加速度,deg/s/s,(积分器的值)
        wdotK   %计算角加速度时用的K
        wdotX   %计算角加速度时滤波后的角速度
    end
    
    methods
        %% 构造函数
        function obj = filter_single(para)
            d2r = pi/180;
            obj.motion = motionDetector_gyro(para.gyro0, para.dt, 0.8);
            obj.pos = para.p0;
            obj.vel = para.v0;
            obj.att = para.a0;
            Cen = dcmecef2ned(obj.pos(1), obj.pos(2));
            obj.rp = lla2ecef(obj.pos);
            obj.vp = obj.vel*Cen;
            obj.quat = angle2quat(obj.att(1)*d2r, obj.att(2)*d2r, obj.att(3)*d2r);
            obj.dtr = 0;
            obj.dtv = 0;
            obj.bias = [0,0,0,0,0,0];
            obj.T = para.dt;
            lat = obj.pos(1); %deg
            h = obj.pos(3);
            [obj.Rm, obj.Rn] = earthCurveRadius(lat);
            obj.g = gravitywgs84(h, lat);
            obj.dlatdn = 1/(obj.Rm+h);
            obj.dlonde = secd(lat)/(obj.Rn+h);
            obj.P = diag([para.P0_att  *[1,1,1]*d2r, ...
                          para.P0_vel  *[1,1,1], ...
                          para.P0_pos  *[obj.dlatdn,obj.dlonde,1], ...
                          para.P0_dtr  *3e8, ...
                          para.P0_dtv  *3e8, ...
                          para.P0_gyro *[1,1,1]*d2r, ...
                          para.P0_acc  *[1,1,1]*9.8 ...
                         ])^2; %para的P0都是标准差
            obj.Q = diag([para.Q_gyro *[1,1,1]*d2r, ...
                          para.Q_acc  *[1,1,1]*9.8, ...
                          para.Q_acc  *[obj.dlatdn,obj.dlonde,1]*9.8*(obj.T*1), ...
                          para.Q_dtv  *3e8*(obj.T*1), ...
                          para.Q_dtv  *3e8, ...
                          para.Q_dg   *[1,1,1]*d2r, ...
                          para.Q_da   *[1,1,1]*9.8 ...
                         ])^2 * obj.T^2; %para的Q都是标准差
%             obj.Q(6,6) = obj.Q(6,6) * 100; %可以让地向速度估计有噪声,地向速度估计的偏置是高度变化引起的
            obj.Rwb = (para.sigma_gyro*d2r)^2;
            obj.wbDelay = delayN(3, 20);
            obj.arm = para.arm;
            obj.wdot = [0,0,0];
            [K1, K2] = order2LoopCoefD(8, 0.707, obj.T);
            obj.wdotK = [K1,K2];
            obj.wdotX = [0,0,0];
        end
        
        %% 运行函数
        function run(obj, imu, sv, indexP, indexV)
            % indexP,indexV索引都是逻辑值
            %----提取卫星测量(每行一颗卫星)
            rs = sv(:,1:3);     %卫星ecef位置
            vs = sv(:,4:6);     %卫星ecef速度
            rho = sv(:,7);      %测量的伪距
            rhodot = sv(:,8);   %测量的伪距率
            R_rho = sv(:,9);    %伪距噪声方差
            R_rhodot= sv(:,10); %伪距率噪声方差
            %----换简短的变量名
            d2r = pi/180;
            r2d = 180/pi;
            dt = obj.T;
            q = obj.quat;
            v0 = obj.vel;
            lat = obj.pos(1); %deg
            lon = obj.pos(2); %deg
            h = obj.pos(3);
            %----更新地球参数(位置变化小可以不做)
            [obj.Rm, obj.Rn] = earthCurveRadius(lat);
            obj.g = gravitywgs84(h, lat);
            obj.dlatdn = 1/(obj.Rm+h);
            obj.dlonde = secd(lat)/(obj.Rn+h);
            %----运动状态检测
            obj.motion.run(imu(1:3)); %deg/s
            %----计算角加速度
            wdotE = imu(1:3) - obj.wdotX; %误差
            obj.wdot = obj.wdot + obj.wdotK(2)*wdotE; %积分器
            obj.wdotX = obj.wdotX + (obj.wdotK(1)*wdotE+obj.wdot)*obj.T;
            %----角速度延迟
            wbd = obj.wbDelay.push(imu(1:3));
            wbd = (wbd - obj.bias(1:3)) *d2r; %减当前零偏
            %----零偏补偿
            imu = imu - obj.bias;
            wb = imu(1:3) *d2r; %rad
            fb = imu(4:6) *obj.g; %m/s^2
            %----姿态解算
            Omega = [  0,    wb(1),  wb(2),  wb(3);
                    -wb(1),    0,   -wb(3),  wb(2);
                    -wb(2),  wb(3),    0,   -wb(1);
                    -wb(3), -wb(2),  wb(1),    0 ];
            q = q + 0.5*q*Omega*dt;
            q = q / norm(q);
            Cnb = quat2dcm(q);
            Cbn = Cnb';
            %----速度解算
            fn = fb*Cnb;
            v = v0 + (fn+[0,0,obj.g])*dt;
            %----位置解算
            dp = (v0+v)/2*dt; %位置增量
            lat = lat + dp(1)*obj.dlatdn*r2d; %deg
            lon = lon + dp(2)*obj.dlonde*r2d; %deg
            h = h - dp(3);
            %----状态方程
            A = zeros(17);
            A(1:3,12:14) = -Cbn;
            A(4:6,1:3) = [0,-fn(3),fn(2); fn(3),0,-fn(1); -fn(2),fn(1),0];
            A(4:6,15:17) = Cbn;
            A(7,4) = obj.dlatdn;
            A(8,5) = obj.dlonde;
            A(9,6) = -1;
            A(10,11) = 1;
            Phi = eye(17) + A*dt;
            %----状态更新
            P1 = Phi*obj.P*Phi' + obj.Q;
            X = zeros(17,1);
            %----量测维数
            n1 = sum(indexP); %伪距量测个数
            n2 = sum(indexV); %伪距率量测个数
            %----量测更新
            if n1>0 %有卫星量测
                %----根据当前导航结果计算理论相对距离和相对速度
                [rho0, rhodot0, rspu, Cen] = rho_rhodot_cal_geog(rs, vs, [lat,lon,h], v);
                %----构造量测方程,量测量,量测噪声方差阵
                F = jacobi_lla2ecef(lat, lon, h, obj.Rn);
                HA = rspu*F;
                HB = rspu*Cen'; %各行为地理系下卫星指向接收机的单位矢量
                Ha = HA(indexP,:); %取有效的行
                Hb = HB(indexV,:);
                H = zeros(n1+n2,17);
                H(1:n1,7:9) = Ha;
                H(1:n1,10) = -ones(n1,1);
                H((n1+1):end,4:6) = Hb;
                H((n1+1):end,11) = -ones(n2,1);
                %----对测量的伪距伪距率进行杆臂修正-------------------------%
                rho = rho - HB*Cbn*obj.arm'; %如果天线放在惯导位置应该测得的伪距
                vab = cross(wb,obj.arm); %杆臂引起的速度
                rhodot = rhodot - HB*Cbn*vab'; %如果天线放在惯导位置应该测得的伪距率
                %---------------------------------------------------------%
                Z = [rho0(indexP) - rho(indexP); ...
                     rhodot0(indexV) - rhodot(indexV)]; %计算值减测量值
                if obj.motion.state==0 %静止时加入角速度量测
                    H(end+(1:3),12:14) = eye(3);
                    Z = [Z; wbd']; %使用延迟后的角速度,防止机动前几个点的角速度抖动
                    R = diag([R_rho(indexP);R_rhodot(indexV);[1;1;1]*obj.Rwb]);
                else %运动时将伪距率的量测噪声放大
                    R = diag([R_rho(indexP);R_rhodot(indexV)*4]);
                end
                %----滤波
                K = P1*H' / (H*P1*H'+R);
                X = K*Z;
                P1 = (eye(17)-K*H)*P1;
                obj.P = (P1+P1')/2;
                %----状态约束
                Y = [];
                if obj.motion.state==0 %静止时航向修正量约束为0
                    Ysub = zeros(1,17);
                    Ysub(1,1) = Cnb(1,1)*Cnb(1,3);
                    Ysub(1,2) = Cnb(1,2)*Cnb(1,3);
                    Ysub(1,3) = -(Cnb(1,1)^2+Cnb(1,2)^2);
                    Y = [Y; Ysub];
                end
%                 if n1<4 %伪距量测小于4,不修钟差
%                     Ysub = zeros(1,17);
%                     Ysub(1,10) = 1;
%                     Y = [Y; Ysub];
%                 end
%                 if n2<4 %伪距率量测小于4,不修钟频差
%                     Ysub = zeros(1,17);
%                     Ysub(1,11) = 1;
%                     Y = [Y; Ysub];
%                 end
                if abs(obj.bias(1)+X(12)*r2d)>0.1
                    Ysub = zeros(1,17);
                    Ysub(1,12) = 1;
                    Y = [Y; Ysub];
                end
                if abs(obj.bias(2)+X(13)*r2d)>0.1
                    Ysub = zeros(1,17);
                    Ysub(1,13) = 1;
                    Y = [Y; Ysub];
                end
                if abs(obj.bias(3)+X(14)*r2d)>0.1
                    Ysub = zeros(1,17);
                    Ysub(1,14) = 1;
                    Y = [Y; Ysub];
                end
                if abs(obj.bias(4)+X(15)/obj.g)>5e-3
                    Ysub = zeros(1,17);
                    Ysub(1,15) = 1;
                    Y = [Y; Ysub];
                end
                if abs(obj.bias(5)+X(16)/obj.g)>5e-3
                    Ysub = zeros(1,17);
                    Ysub(1,16) = 1;
                    Y = [Y; Ysub];
                end
                if abs(obj.bias(6)+X(17)/obj.g)>5e-3
                    Ysub = zeros(1,17);
                    Ysub(1,17) = 1;
                    Y = [Y; Ysub];
                end
                if ~isempty(Y)
                    X = X - P1*Y'/(Y*P1*Y')*Y*X;
                end
            end
            %----运动到静止时增大姿态失准角,零偏对应的P
%             if obj.motion.state0==1 && obj.motion.state==0
%                 obj.P(12,12) = 3e-7; %(0.03/180*pi)^2
%                 obj.P(13,13) = 3e-7;
%                 obj.P(14,14) = 3e-7;
%                 obj.P(15,15) = 1e-4; %(0.01)^2
%                 obj.P(16,16) = 1e-4;
%                 obj.P(17,17) = 1e-4;
%             end
            %----导航修正
            q = quatCorr(q, X(1:3)');
            v = v - X(4:6)';
            lat = lat - X(7)*r2d; %deg
            lon = lon - X(8)*r2d; %deg
            h = h - X(9);
            %----更新导航参数
            obj.pos = [lat,lon,h];
            obj.vel = v;
            [r1,r2,r3] = quat2angle(q);
            obj.att = [r1,r2,r3]*r2d; %deg
            obj.rp = lla2ecef(obj.pos);
            Cen = dcmecef2ned(lat, lon);
            obj.vp = v*Cen;
            obj.quat = q;
            obj.dtr = X(10)/299792458; %s
            obj.dtv = X(11)/299792458; %s/s
            obj.bias(1:3) = obj.bias(1:3) + X(12:14)'*r2d; %deg/s
            obj.bias(4:6) = obj.bias(4:6) + X(15:17)'/obj.g; %g
        end
        
    end %end methods
    
end %end classdef