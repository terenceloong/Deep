classdef accJumpDetector < handle
% 加速度突变检测
% 加速度突变状态要维持一会,因为加速度突变后那段时间卫星信号不稳定

    properties
        state   %突变状态
        flag    %首次运行标志
        acc0    %上次加速度值
        amThr   %加速度模长阈值
        cnt     %计数器
        N       %计数值
    end
    
    methods
        % 构造函数
        function obj = accJumpDetector(dt)
            % dt:采样时间间隔,s
            obj.state = 0;
            obj.flag = 0;
            obj.acc0 = [0,0,0];
            obj.amThr = 1000*dt; %100g/s
            obj.cnt = 0;
            obj.N = 0.1/dt; %100ms
        end
        
        % 运行函数
        function run(obj, acc)
            if obj.flag==0
                obj.flag = 1;
                obj.acc0 = acc;
            end
            if obj.state==0 %没突变
                if norm(obj.acc0-acc)>obj.amThr
                    obj.state = 1;
                    obj.cnt = 0;
                end
            else %有突变
                if norm(obj.acc0-acc)>obj.amThr
                    obj.cnt = 0;
                else
                    obj.cnt = obj.cnt + 1;
                end
                if obj.cnt==obj.N
                    obj.state = 0;
                end
            end
            obj.acc0 = acc; %保存上次加速度
        end
        
    end %end methods
    
end %end classdef