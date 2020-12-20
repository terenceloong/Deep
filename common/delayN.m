classdef delayN < handle
% n点延迟,输入一个数,输出n点之前的数
    
    properties
        buff      
        len %缓冲区长度
        ptr    
    end
    
    methods
        function obj = delayN(m, n)
            % m个数(行向量),延迟n个点
            obj.buff = zeros(n,m);
            obj.len = n;
            obj.ptr = 1;
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
        end
        
    end
    
end