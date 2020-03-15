classdef var_rec < handle
% 固定窗口递推计算方差
    
    properties (GetAccess = public, SetAccess = private)
        flag    %启动标志
        buff    %数据缓存
        size    %缓存大小
        index   %缓存索引,从0开始
        E       %当前计算的均值
        D       %当前计算的方差
    end
    
    methods
        % 构造函数
        function obj = var_rec(n)
            obj.flag = 0;
            obj.buff = zeros(1,n);
            obj.size = n;
            obj.index = 0;
            obj.E = 0;
            obj.D = 0;
        end
        
        % 更新函数
        function update(obj, x1)
            if obj.flag
                n = obj.size;
                k = obj.index + 1;
                x0 = obj.buff(k);
                E0 = obj.E; %上次的均值
                D0 = obj.D; %上次的方差
                %------------------------------------
                E1 = E0 + (x1-x0)/n; %计算均值
                D1 = D0 + ((x1-E1)^2 - (x0-E0)^2 - 2*(E1-E0)*(E0*n-x0) + (n-1)*(E1^2-E0^2))/n;
                %------------------------------------
                obj.E = E1; %更新均值
                obj.D = D1; %更新方差
                obj.buff(k) = x1;
                if k==n %更新索引
                    obj.index = 0;
                else
                    obj.index = k;
                end
            else
                obj.flag = 1;
                obj.buff(:) = x1; %将缓存全填上x1
                obj.E = x1;
                obj.index = 1;
            end
        end
        
        % 重启函数
        function restart(obj, n)
            obj.flag = 0;
            obj.buff = zeros(1,n);
            obj.size = n;
            obj.index = 0;
            obj.E = 0;
            obj.D = 0;
        end
        
    end
    
end %end classdef