classdef INS_GRC < handle
% 惯性导航
% GRC:地理系,速率式,粗糙的解算
    
    properties
        firstFlag  %首次运行标志
        pos        %位置,纬经高
        vel        %速度,地理系
        att        %姿态
        rp         %位置,ecef
        vp         %速度,ecef
        quat       %姿态四元数
        geogInfo   %地理信息
        imu0       %上次的IMU输出
        T          %更新周期
        accJump    %加速度突变检测(应对仿真时可能出现的加速度突变的情况)
    end
    
    methods
        %% 构造函数
        function obj = INS_GRC(para)
            d2r = pi/180;
            obj.firstFlag = 0;
            obj.pos = para.p0;
            obj.vel = para.v0;
            obj.att = para.a0;
            Cen = dcmecef2ned(obj.pos(1), obj.pos(2));
            obj.rp = lla2ecef(obj.pos);
            obj.vp = obj.vel*Cen;
            obj.quat = angle2quat(obj.att(1)*d2r, obj.att(2)*d2r, obj.att(3)*d2r);
            obj.geogInfo = geogInfo_cal(obj.pos, obj.vel);
            obj.imu0 = [0,0,0,0,0,0];
            obj.T = para.dt;
            obj.accJump = accJumpDetector(obj.T);
        end
        
        %% 解算函数
        function solve(obj, imu, flag)
            % flag==0,更新所有导航参数
            % flag~=0,更新部分导航参数
            %----换简短的变量名
            r2d = 180/pi;
            dt = obj.T;
            q = obj.quat;
            v0 = obj.vel;
            %----首次运行时记录IMU值
            if obj.firstFlag==0
                obj.imu0 = imu;
                obj.firstFlag = 1;
            end
            %----加速度突变检测
            obj.accJump.run(imu(4:6));
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
            %----角增量和速度增量
            dv = (fb0+fb1)/2*dt;
            dtheta = (wb0+wb1)/2*dt;
            %----姿态解算
            Cnb = quat2dcm(q); %上次的姿态阵
            winn = obj.geogInfo.wien + obj.geogInfo.wenn;
            winb = winn * Cnb';
            X = dtheta - winb*dt; %角增量修正
            phi = norm(X);
            if phi>1e-12
                dq = [cos(phi/2), X/phi*sin(phi/2)];
                q = quatmultiply(q, dq);
            end
%             wb0 = wb0 - winb;
%             wb1 = wb1 - winb;
%             q = RK2(@fun_dq, q, dt, wb0, wb1);
            obj.quat = q / norm(q);
            %----速度解算
            winn2 = winn + obj.geogInfo.wien;
            dvc = 0.5*cross(X,dv); %速度增量补偿量
%             dvc = 0.5*cross(dtheta,dv); %速度增量补偿量
            obj.vel = v0 + (dv+dvc)*Cnb + ([0,0,obj.geogInfo.g]-cross(winn2,v0))*dt;
            %----位置解算
            dp = (v0+obj.vel)/2*dt; %位置增量
            obj.pos(1) = obj.pos(1) + dp(1)*obj.geogInfo.dlatdn*r2d; %deg
            obj.pos(2) = obj.pos(2) + dp(2)*obj.geogInfo.dlonde*r2d; %deg
            obj.pos(3) = obj.pos(3) - dp(3);
            %----更新导航参数
            obj.imu0 = imu; %保存IMU数据
            if flag==0
                obj.rp = lla2ecef(obj.pos);
                Cen = dcmecef2ned(obj.pos(1), obj.pos(2));
                obj.vp = obj.vel*Cen;
                [r1,r2,r3] = quat2angle(obj.quat);
                obj.att = [r1,r2,r3]*r2d; %deg
                obj.geogInfo = geogInfo_cal(obj.pos, obj.vel); %更新地理信息
            end
        end
        
        %% 导航修正
        function correct(obj, X)
            % X为行向量,[phi,dv,dp]
            r2d = 180/pi;
            obj.quat = quatCorr(obj.quat, X(1:3));
            obj.vel = obj.vel - X(4:6);
            obj.pos(1) = obj.pos(1) - X(7)*obj.geogInfo.dlatdn*r2d; %deg
            obj.pos(2) = obj.pos(2) - X(8)*obj.geogInfo.dlonde*r2d; %deg
            obj.pos(3) = obj.pos(3) + X(9);
            % 更新导航参数
            obj.rp = lla2ecef(obj.pos);
            Cen = dcmecef2ned(obj.pos(1), obj.pos(2));
            obj.vp = obj.vel*Cen;
            [r1,r2,r3] = quat2angle(obj.quat);
            obj.att = [r1,r2,r3]*r2d; %deg
            obj.geogInfo = geogInfo_cal(obj.pos, obj.vel); %更新地理信息
        end
        
    end %end methods
    
end %end classdef