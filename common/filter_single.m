classdef filter_single < handle
% 单天线导航滤波器,位置速度都是惯导的
    
    properties
        firstFlag  %首次运行标志
        pos        %位置,纬经高
        vel        %速度,地理系
        att        %姿态
        rp         %位置,ecef
        vp         %速度,ecef
        quat       %姿态四元数
        dtr        %钟差,s
        dtv        %钟频差,s/s
        geogInfo   %地理信息
        imu0       %上次的IMU输出(零偏补偿后)
        bias       %零偏,[gyro,acc],[rad/s,m/s^2]
        T          %更新周期
        P          %P阵
        Q          %Q阵
        Rwb        %陀螺仪输出噪声方差
        wbDelay    %延迟的角速度输出
        arm        %杆臂矢量,体系下IMU指向天线
        wdotCal    %角加速度计算模块
        wdot       %角加速度值,rad/s^2
        motion     %运动状态检测
        accJump    %加速度突变检测(应对仿真时可能出现的加速度突变的情况)
    end
    
    methods
        %% 构造函数
        function obj = filter_single(para)
            d2r = pi/180;
            g0 = 9.8; %重力加速度近似值
            c = 3e8; %光速近似值
            obj.firstFlag = 0;
            obj.pos = para.p0;
            obj.vel = para.v0;
            obj.att = para.a0;
            Cen = dcmecef2ned(obj.pos(1), obj.pos(2));
            obj.rp = lla2ecef(obj.pos);
            obj.vp = obj.vel*Cen;
            obj.quat = angle2quat(obj.att(1)*d2r, obj.att(2)*d2r, obj.att(3)*d2r);
            obj.dtr = 0;
            obj.dtv = 0;
            obj.geogInfo = geogInfo_cal(obj.pos, obj.vel);
            obj.imu0 = [0,0,0,0,0,0];
            obj.bias = [0,0,0,0,0,0];
            obj.T = para.dt;
            obj.P = diag([para.P0_att  *[1,1,1]*d2r, ...
                          para.P0_vel  *[1,1,1], ...
                          para.P0_pos  *[obj.geogInfo.dlatdn,obj.geogInfo.dlonde,1], ...
                          para.P0_dtr  *c, ...
                          para.P0_dtv  *c, ...
                          para.P0_gyro *[1,1,1]*d2r, ...
                          para.P0_acc  *[1,1,1]*g0 ...
                         ])^2; %para的P0都是标准差
            obj.Q = diag([para.Q_gyro *[1,1,1]*d2r, ...
                          para.Q_acc  *[1,1,1]*g0, ...
                          para.Q_acc  *[obj.geogInfo.dlatdn,obj.geogInfo.dlonde,1]*g0*(obj.T*1), ...
                          para.Q_dtv  *c*(obj.T*1), ...
                          para.Q_dtv  *c, ...
                          para.Q_dg   *[1,1,1]*d2r, ...
                          para.Q_da   *[1,1,1]*g0 ...
                         ])^2 * obj.T^2; %para的Q都是标准差
            obj.Rwb = (para.sigma_gyro*d2r)^2;
            obj.wbDelay = delayN(20, 3);
            obj.arm = para.arm;
            obj.wdotCal = omegadot_cal(obj.T, 3);
            obj.wdot = [0,0,0];
            obj.motion = motionDetector_gyro_vel(para.gyro0, obj.T, 0.8);
            obj.accJump = accJumpDetector(obj.T);
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
            r2d = 180/pi;
            c = 299792458;
            dt = obj.T;
            q = obj.quat;
            v0 = obj.vel;
            lat = obj.pos(1); %deg
            lon = obj.pos(2); %deg
            h = obj.pos(3);
            %----首次运行时记录IMU值
            if obj.firstFlag==0
                obj.imu0 = imu;
                obj.firstFlag = 1;
            end
            %----加速度突变检测
            obj.accJump.run(imu(4:6));
            %----运动状态检测
            obj.motion.run(imu(1:3)*r2d, obj.vel); %deg/s
            %----计算角加速度
            obj.wdot = obj.wdotCal.run(imu(1:3)); %rad/s
            %----角速度延迟
            wbd = obj.wbDelay.push(imu(1:3));
            wbd = wbd - obj.bias(1:3); %减当前零偏
            %----零偏补偿
            imu = imu - obj.bias;
            %----上次的IMU值
            if norm(obj.imu0(1:3)-imu(1:3))>(17.5*dt) %角速度突变(1000deg/s^2)
                wb0 = imu(1:3);
            else
                wb0 = obj.imu0(1:3);
            end
            if obj.accJump.state==1 && obj.accJump.cnt==0 %加速度突变
                fb0 = imu(4:6);
            else
                fb0 = obj.imu0(4:6);
            end
            %----当前的IMU值
            wb1 = imu(1:3);
            fb1 = imu(4:6);
            %----姿态解算
            Cnb = quat2dcm(q); %上次的姿态阵
            Cbn = Cnb';
%             winn = obj.geogInfo.wien + obj.geogInfo.wenn;
%             winb = winn * Cbn;
%             wb0 = wb0 - winb;
%             wb1 = wb1 - winb;
            wenb = obj.geogInfo.wenn * Cbn;
            wb0 = wb0 - wenb; %刨除地理系旋转,没刨地球自转
            wb1 = wb1 - wenb;
            q = RK2(@fun_dq, q, dt, wb0, wb1);
            q = q / norm(q);
            %----速度解算
            winn2 = 2*obj.geogInfo.wien + obj.geogInfo.wenn;
            fb = (fb0+fb1)/2;
            wb = (wb0+wb1)/2;
            dv = fb*dt; %速度增量
            dtheta = wb*dt; %角度增量
            dvc = 0.5*cross(dtheta,dv); %速度增量补偿量
            v = v0 + (dv+dvc)*Cnb + ([0,0,obj.geogInfo.g]-cross(winn2,v0))*dt;
            %----位置解算
            dp = (v0+v)/2*dt; %位置增量
            lat = lat + dp(1)*obj.geogInfo.dlatdn*r2d; %deg
            lon = lon + dp(2)*obj.geogInfo.dlonde*r2d; %deg
            h = h - dp(3);
            %----状态方程
            Cnb = quat2dcm(q);
            Cbn = Cnb';
            fn = fb1*Cnb;
            A = zeros(17);
%             A(1:3,1:3) = [0,winn(3),-winn(2); -winn(3),0,winn(1); winn(2),-winn(1),0];
            A(1:3,12:14) = -Cbn;
            A(4:6,1:3) = [0,-fn(3),fn(2); fn(3),0,-fn(1); -fn(2),fn(1),0];
%             A(4:6,4:6) = [0,winn2(3),-winn2(2); -winn2(3),0,winn2(1); winn2(2),-winn2(1),0];
            A(4:6,15:17) = Cbn;
            A(7,4) = obj.geogInfo.dlatdn;
            A(8,5) = obj.geogInfo.dlonde;
            A(9,6) = -1;
            A(10,11) = 1;
            Phi = eye(17) + A*dt; % + (A*dt)^2/2;
            %----状态更新
            P1 = Phi*obj.P*Phi' + obj.Q;
            X = zeros(17,1);
            %----量测维数
            n1 = sum(indexP); %伪距量测个数
            n2 = sum(indexV); %伪距率量测个数
            %----量测更新
            if n1>0 && obj.accJump.state==0 %有卫星量测并且没有加速度突变
                %----根据当前导航结果计算理论相对距离和相对速度
                [rho0, rhodot0, rspu, Cen] = rho_rhodot_cal_geog(rs, vs, [lat,lon,h], v);
                %----构造量测方程,量测量,量测噪声方差阵
                S = -sum(rspu.*vs,2);
                cm = 1 + S/c; %光速修正项
                F = jacobi_lla2ecef(lat, lon, h, obj.geogInfo.Rn);
                HA = rspu*F;
                HB = rspu*Cen'; %各行为地理系下卫星指向接收机的单位矢量
                Ha = HA(indexP,:); %取有效的行
                Hb = HB(indexV,:);
                H = zeros(n1+n2,17);
                H(1:n1,7:9) = Ha;
                H(1:n1,10) = -ones(n1,1);
                H((n1+1):end,4:6) = Hb;
                H((n1+1):end,11) = -cm(indexV);
                %----对测量的伪距伪距率进行杆臂修正-------------------------%
                rho = rho - HB*Cbn*obj.arm'; %如果天线放在惯导位置应该测得的伪距
                vab = cross(wb1,obj.arm); %杆臂引起的速度
                rhodot = rhodot - HB*Cbn*vab'; %如果天线放在惯导位置应该测得的伪距率
                %---------------------------------------------------------%
                Z = [rho0(indexP) - rho(indexP); ...
                     rhodot0(indexV) - rhodot(indexV).*cm(indexV)]; %计算值减测量值
                if obj.motion.state==0 %静止时加入角速度量测
                    H(end+(1:3),12:14) = eye(3);
                    Z = [Z; wbd']; %使用延迟后的角速度,防止机动前几个点的角速度抖动
                    R = diag([R_rho(indexP);R_rhodot(indexV);[1;1;1]*obj.Rwb]);
                else %运动时将伪距率的量测噪声放大
                    R = diag([R_rho(indexP);R_rhodot(indexV)*1]);
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
%                 if abs(obj.bias(1)+X(12))*r2d>0.1
%                     Ysub = zeros(1,17);
%                     Ysub(1,12) = 1;
%                     Y = [Y; Ysub];
%                 end
%                 if abs(obj.bias(2)+X(13))*r2d>0.1
%                     Ysub = zeros(1,17);
%                     Ysub(1,13) = 1;
%                     Y = [Y; Ysub];
%                 end
%                 if abs(obj.bias(3)+X(14))*r2d>0.1
%                     Ysub = zeros(1,17);
%                     Ysub(1,14) = 1;
%                     Y = [Y; Ysub];
%                 end
%                 if abs(obj.bias(4)+X(15))>0.05
%                     Ysub = zeros(1,17);
%                     Ysub(1,15) = 1;
%                     Y = [Y; Ysub];
%                 end
%                 if abs(obj.bias(5)+X(16))>0.05
%                     Ysub = zeros(1,17);
%                     Ysub(1,16) = 1;
%                     Y = [Y; Ysub];
%                 end
%                 if abs(obj.bias(6)+X(17))>0.05
%                     Ysub = zeros(1,17);
%                     Ysub(1,17) = 1;
%                     Y = [Y; Ysub];
%                 end
                if ~isempty(Y)
                    X = X - P1*Y'/(Y*P1*Y')*Y*X;
                end
            end
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
            obj.dtr = X(10)/c; %s
            obj.dtv = X(11)/c; %s/s
            obj.bias(1:3) = obj.bias(1:3) + X(12:14)'; %rad/s
            obj.bias(4:6) = obj.bias(4:6) + X(15:17)'; %m/s^2
            obj.geogInfo = geogInfo_cal(obj.pos, obj.vel); %更新地理信息
            obj.imu0 = imu; %保存IMU数据
        end
        
    end %end methods
    
end %end classdef