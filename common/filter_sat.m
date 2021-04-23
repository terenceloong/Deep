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
            obj.P = diag([para.P0_pos *[1,1,1], ...
                          para.P0_vel *[1,1,1], ...
                          para.P0_acc *[1,1,1], ...
                          para.P0_dtr *c, ...
                          para.P0_dtv *c ...
                         ])^2; %para的P0都是标准差
            obj.Q = diag([para.Q_pos *[1,1,1], ...
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
            A(1,4) = 1;
            A(2,5) = 1;
            A(3,6) = 1;
            A(4,7) = 1;
            A(5,8) = 1;
            A(6,9) = 1;
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
                En = rspu*Cen'; %各行为地理系下卫星指向接收机的单位矢量
                H = zeros(n1+n2,11);
                H(1:n1,1:3) = En(indexP,:);
                H(1:n1,10) = -ones(n1,1);
                H((n1+1):end,4:6) = En(indexV,:);
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
                %----Huber加权(残差校验)
%                 P1 = (P1+P1')/2; %需要保证P为对称阵,否则开方时会出现复数
%                 P_sqrt = sqrtm(P1); %P的平方根
%                 R_diag = diag(R); %R的对角线元素
%                 R_sqrt_diag = sqrt(R_diag); %R的对角线元素的平方根
%                 gamma = 1.3; %Huber系数
%                 for k=1:2 %算两次
%                     Psi_P_diag = HuberWeight(P_sqrt\X, gamma); %状态量的权值
%                     Psi_R_diag = HuberWeight((Z-H*X)./R_sqrt_diag, gamma); %量测量的权值
%                     P0 = P_sqrt * diag(1./Psi_P_diag) * P_sqrt; %加权后的P阵
%                     R0 = diag(R_diag./Psi_R_diag); %加权后的R阵
%                     K = P0*H' / (H*P0*H'+R0);
%                     X = K*Z;
%                     if any(imag(X))
%                         error('Complex number in the filter!')
%                     end
%                 end
%                 P1 = P0;
                %----Huber加权(简化)
                R_diag = diag(R); %R的对角线元素
                R_sqrt_diag = sqrt(R_diag); %R的对角线元素的平方根
                gamma = 1.3; %Huber系数
                for k=1:2 %算两次
                    Psi_R_diag = HuberWeight((Z-H*X)./R_sqrt_diag, gamma); %量测量的权值
                    R0 = diag(R_diag./Psi_R_diag); %加权后的R阵
                    K = P1*H' / (H*P1*H'+R0);
                    X = K*Z;
                end
                %----计算P阵
                P1 = (eye(11)-K*H)*P1;
            end
            %----更新P阵
            obj.P = (P1+P1')/2;
            %----导航修正
            lat = lat - X(1)*obj.geogInfo.dlatdn*r2d; %deg
            lon = lon - X(2)*obj.geogInfo.dlonde*r2d; %deg
            h = h + X(3);
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