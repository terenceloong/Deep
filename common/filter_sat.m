classdef filter_sat < handle
% 卫星导航滤波器
    
    properties
        pos        %位置,纬经高
        vel        %速度,地理系
        rp         %位置,ecef
        vp         %速度,ecef
        acc        %加速度
        dtr        %钟差,s
        dtv        %钟频差,s/s
        geogInfo   %地理信息
        T          %更新周期
        P          %P阵
        Q          %Q阵
    end
    
    methods
        %% 构造函数
        function obj = filter_sat(para)
            c = 3e8; %光速近似值
            obj.pos = para.p0;
            obj.vel = para.v0;
            Cen = dcmecef2ned(obj.pos(1), obj.pos(2));
            obj.rp = lla2ecef(obj.pos);
            obj.vp = obj.vel*Cen;
            obj.acc = [0,0,0];
            obj.dtr = 0;
            obj.dtv = 0;
            obj.geogInfo = geogInfo_cal(obj.pos, obj.vel);
            obj.T = para.dt;
            obj.P = diag([para.P0_pos *[obj.geogInfo.dlatdn,obj.geogInfo.dlonde,1], ...
                          para.P0_vel *[1,1,1], ...
                          para.P0_acc *[1,1,1], ...
                          para.P0_dtr *c, ...
                          para.P0_dtv *c ...
                         ])^2; %para的P0都是标准差
            obj.Q = diag([para.Q_pos *[obj.geogInfo.dlatdn,obj.geogInfo.dlonde,1], ...
                          para.Q_vel *[1,1,1], ...
                          para.Q_acc *[1,1,1], ...
                          para.Q_dtr *c, ...
                          para.Q_dtv *c ...
                         ])^2 * obj.T^2; %para的Q都是标准差
        end
        
        %% 运行函数
        function [innP, innV] = run(obj, sv, indexP, indexV)
            % indexP,indexV索引都是逻辑值
            n = length(indexP);
            innP = NaN(1,n); %伪距新息(伪距的Z)
            innV = NaN(1,n); %伪距率新息(伪距率的Z)
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
            v0 = obj.vel;
            lat = obj.pos(1); %deg
            lon = obj.pos(2); %deg
            h = obj.pos(3);
            %----速度解算
            v = v0 + obj.acc*dt;
            %----位置解算
            dp = (v0+v)/2*dt; %位置增量
            lat = lat + dp(1)*obj.geogInfo.dlatdn*r2d; %deg
            lon = lon + dp(2)*obj.geogInfo.dlonde*r2d; %deg
            h = h - dp(3);
            %----更新钟差
            obj.dtr = obj.dtr + obj.dtv*dt;
            %----状态方程
            A = zeros(11);
            A(1,4) = obj.geogInfo.dlatdn;
            A(2,5) = obj.geogInfo.dlonde;
            A(3,6) = -1;
            A(4:6,7:9) = eye(3);
            A(10,11) = 1;
            Phi = eye(11) + A*dt + (A*dt)^2/2;
            %----状态更新
            P1 = Phi*obj.P*Phi' + obj.Q;
            X = zeros(11,1);
            %----量测维数
            n1 = sum(indexP); %伪距量测个数
            n2 = sum(indexV); %伪距率量测个数
            %----量测更新
            if n1>0 %有卫星量测
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
                H = zeros(n1+n2,11);
                H(1:n1,1:3) = Ha;
                H(1:n1,10) = -ones(n1,1);
                H((n1+1):end,4:6) = Hb;
                H((n1+1):end,11) = -cm(indexV);
                %-------------------修正钟差钟频差-------------------------%
                rho = rho - obj.dtr*c;
                rhodot = rhodot - obj.dtv*c;
                %---------------------------------------------------------%
                Z = [rho0(indexP) - rho(indexP); ...
                     rhodot0(indexV) - rhodot(indexV).*cm(indexV)]; %计算值减测量值
                R = diag([R_rho(indexP);R_rhodot(indexV)]);
                %----输出新息
                innP(indexP) = Z(1:n1);
                innV(indexV) = Z(n1+1:n1+n2);
                %----滤波
                K = P1*H' / (H*P1*H'+R);
                X = K*Z;
                P2 = (eye(11)-K*H)*P1;
                %----残差校验(删残差大的行)
                Z0 = Z - H*X; %残差
                Z0_rhodot = Z0(n1+1:end); %伪距率残差
                ie = n1 + find(abs(Z0_rhodot)>0.6)'; %残差大的索引
                if ~isempty(ie) %删除残差大的量测,重新滤波
                    Z(ie) = [];
                    H(ie,:) = [];
                    R(ie,:) = [];
                    R(:,ie) = [];
                    K = P1*H' / (H*P1*H'+R);
                    X = K*Z;
                    P2 = (eye(11)-K*H)*P1;
                end
            end
            %----更新P阵
            obj.P = (P2+P2')/2;
            %----导航修正
            lat = lat - X(1)*r2d; %deg
            lon = lon - X(2)*r2d; %deg
            h = h - X(3);
            v = v - X(4:6)';
            %----更新导航参数
            obj.pos = [lat,lon,h];
            obj.vel = v;
            obj.rp = lla2ecef(obj.pos);
            Cen = dcmecef2ned(lat, lon);
            obj.vp = v*Cen;
            obj.acc = obj.acc - X(7:9)';
            obj.dtr = obj.dtr + X(10)/c; %s
            obj.dtv = obj.dtv + X(11)/c; %s/s
            obj.geogInfo = geogInfo_cal(obj.pos, obj.vel); %更新地理信息
        end
        
    end %end methods
    
end %end classdef