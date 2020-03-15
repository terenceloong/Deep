classdef mean_rec < handle
% 固定窗口递推计算均值
    
    properties (GetAccess = public, SetAccess = private)
        flag    %启动标志
        buff    %数据缓存
        size    %缓存大小
        index   %缓存索引,从0开始
        E       %当前计算的均值
    end
    
    methods
        % 构造函数
        function obj = mean_rec(n)
            % n:缓存空间大小
            obj.flag = 0;
            obj.buff = zeros(1,n);
            obj.size = n;
            obj.index = 0;
            obj.E = 0;
        end
        
        % 更新函数
        function update(obj, x1)
            % x1:当前数据
            if obj.flag
                n = obj.size;
                k = obj.index + 1;
                x0 = obj.buff(k);
                %------------------------------------
                obj.E = obj.E + (x1-x0)/n; %计算均值
                %------------------------------------
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
        end
        
    end %end methods
    
end %end classdef