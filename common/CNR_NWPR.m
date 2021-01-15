classdef CNR_NWPR < handle
% 使用窄带宽带功率比值法计算载噪比

    properties
        NWmean     %NBP/WBP的均值
        Nd         %一个数据段的点数
    end
    
    methods
        function obj = CNR_NWPR(N, M)
            % N:一个数据段的点数
            % M:平均数据段数
            obj.Nd = N;
            obj.NWmean = mean_rec(M);
        end
        
        function CN0 = cal(obj, Is, Qs)
            WBP = sum(Is.^2 + Qs.^2); %宽带功率,所有点的功率求和
            NBP = sum(Is)^2 + sum(Qs)^2; %窄带功率,所有点先求和再算功率
            obj.NWmean.update(NBP/WBP);
            Z = obj.NWmean.E;
            S = (Z-1) / (obj.Nd-Z) * 1000; %积分时间固定为1ms
            if S>10
                CN0 = 10*log10(S);
            else
                CN0 = 10;
            end
        end
        
    end
    
end %end classdef