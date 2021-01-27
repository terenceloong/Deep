classdef motionDetector_gyro < handle
% 使用陀螺仪输出做运动状态检测
    
    properties
        state0  %上次的运动状态
        state   %运动状态,0表示静止,1表示运动
        gyro0   %初始陀螺仪零偏,deg/s
        wmt     %角速度模长阈值,deg/s
        cnt     %计数器
        N0      %检测到几个点变为运动
        N1      %检测到几个点变为静止
    end
    
    methods
        % 构造函数
        function obj = motionDetector_gyro(gyro0, dt, wmt)
            % dt:角速度采样时间间隔,s
            obj.state0 = 0;
            obj.state = 0;
            obj.gyro0 = gyro0;
            obj.wmt = wmt;
            obj.cnt = 0;
            obj.N0 = 3; %固定3个点
            obj.N1 = 2/dt; %2s内的点数
        end
        
        % 运行函数
        function run(obj, gyro)
            obj.state0 = obj.state; %记录上次运动状态
            wm = norm(gyro-obj.gyro0); %角速度模长
            if obj.state==0 %静止状态
                if wm<obj.wmt
                    obj.cnt = 0;
                else
                    obj.cnt = obj.cnt+1;
                end
                if obj.cnt==obj.N0 %连续N0个点角速度大于阈值,认为运动
                    obj.cnt = 0;
                    obj.state = 1;
                end
            else %运动状态
                if wm>obj.wmt
                    obj.cnt = 0;
                else
                    obj.cnt = obj.cnt+1;
                end
                if obj.cnt==obj.N1 %连续N1个点角速度小于阈值,认为静止
                    obj.cnt = 0;
                    obj.state = 0;
                end
            end
        end
        
    end %end methods
    
end %end classdef