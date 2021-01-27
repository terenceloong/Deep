classdef motionDetector_gyro_vel < handle
% 使用陀螺仪输出和速度做运动状态检测  
    
    properties
        state0  %上次的运动状态
        state   %运动状态,0表示静止,1表示运动
        gyro0   %初始陀螺仪零偏,deg/s
        wmThr   %角速度模长阈值,deg/s
        vmThr   %速度模长阈值,m/s
        wCnt    %角速度计数器
        vCnt    %速度计数器
        wN0     %角速度计数值,运动状态0->1
        wN1     %角速度计数值,运动状态1->0
        vN0     %速度计数值,运动状态0->1
        vN1     %速度计数值,运动状态1->0
    end
    
    methods
        % 构造函数
        function obj = motionDetector_gyro_vel(gyro0, dt, wmThr)
            % dt:采样时间间隔,s
            obj.state0 = 0;
            obj.state = 0;
            obj.gyro0 = gyro0;
            obj.wmThr = wmThr;
            obj.vmThr = 0.25;
            obj.wCnt = 0;
            obj.vCnt = 0;
            obj.wN0 = 3;
            obj.wN1 = 2/dt; %2s内的点数
            obj.vN0 = 3;
            obj.vN1 = 2/dt; %2s内的点数
        end
        
        % 运行函数
        function run(obj, gyro, vel)
            obj.state0 = obj.state; %记录上次运动状态
            wm = norm(gyro-obj.gyro0); %角速度模长
            vm = norm(vel); %速度模长
            if obj.state==0 %静止状态
                if wm<obj.wmThr
                    obj.wCnt = 0;
                else
                    obj.wCnt = obj.wCnt + 1;
                end
                if vm<obj.vmThr
                    obj.vCnt = 0;
                else
                    obj.vCnt = obj.vCnt + 1;
                end
                if obj.wCnt>=obj.wN0 || obj.vCnt>=obj.vN0
                    obj.wCnt = 0;
                    obj.vCnt = 0;
                    obj.state = 1;
                end
            else %运动状态
                if wm>obj.wmThr
                    obj.wCnt = 0;
                else
                    obj.wCnt = obj.wCnt + 1;
                end
                if vm>obj.vmThr
                    obj.vCnt = 0;
                else
                    obj.vCnt = obj.vCnt + 1;
                end
                if obj.wCnt>=obj.wN1 && obj.vCnt>=obj.vN1
                    obj.wCnt = 0;
                    obj.vCnt = 0;
                    obj.state = 0;
                end
            end
        end
        
    end %end methods
    
end %end classdef