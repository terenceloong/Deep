classdef delayN < handle
% n点延迟,输入一个数,输出n点之前的数
    
    properties
        buff
        len  %缓冲区长度
        ptr
        cnt
    end
    
    methods
        function obj = delayN(m, n)
            % m:延迟点数
            % n:数据维数
            obj.buff = zeros(m,n);
            obj.len = m;
            obj.ptr = 1;
            obj.cnt = 0;
        end
        
        function out = push(obj, in)
            % 先取后存
            k = obj.ptr;
            out = obj.buff(k,:);
            obj.buff(k,:) = in;
            k = k+1;
            if k>obj.len
                k = 1;
            end
            obj.ptr = k;
            % 开始数不够的情况下输出原值
            if obj.cnt<obj.len
                obj.cnt = obj.cnt + 1;
                out = in;
            end
        end
        
    end
    
end