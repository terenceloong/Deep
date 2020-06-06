classdef sigqual_indicator < handle
% 信号质量指示器
% 接收一个比特的全部数据,根据数据符号将相关器输出全折到正半平面
% 计算I路数据的均值和Q路数据的标准差
% 如果信号良好,信号电平的模长应该大于噪声的半径

    properties
        quality    %信号质量
        buffI      %一个比特的I路数据缓存
        buffQ      %一个比特的Q路数据缓存
        index      %缓存索引,从0开始
        N          %一个比特的数据点数
        Im         %I路数据的均值
        Q2m        %Q路数据平方的均值,也就是其方差
    end
    
    methods
        % 构造函数
        function obj = sigqual_indicator(buffSize, N, m)
            % buffSize:数据缓存长度
            % N:一个比特的数据点数
            % m:计算均值窗口长度
            obj.quality = 0;
            obj.buffI = zeros(1,buffSize);
            obj.buffQ = zeros(1,buffSize);
            obj.index = 0;
            obj.N = N;
            obj.Im = mean_rec(m);
            obj.Q2m = mean_rec(m);
        end
        
        % 运行函数
        function run(obj, I, Q)
            obj.index = obj.index + 1;
            ki = obj.index;
            n = obj.N; %一个比特的数据点数
            obj.buffI(ki) = I;
            obj.buffQ(ki) = Q;
            if ki==n %存够一个比特的数
                obj.index = 0;
                bit = sign(sum(obj.buffI(1:n))/n); %比特符号
                for k=1:n
                    obj.Im.update(obj.buffI(k)*bit);
                    obj.Q2m.update(obj.buffQ(k)^2);
                end
                ratio = obj.Im.E / sqrt(obj.Q2m.E);
                if ratio>3
                    obj.quality = 2; %强信号
                elseif ratio>2
                    obj.quality = 1; %弱信号
                else
                    obj.quality = 0; %失锁
                end
            end
        end
        
        % 改变一个比特的数据点数
        function changeN(obj, N, m)
            % N:一个比特的数据点数
            % m:计算均值窗口长度
            obj.quality = 0;
            obj.index = 0;
            obj.N = N;
            obj.Im.restart(m);
            obj.Q2m.restart(m);
        end
        
    end
    
end %end classdef