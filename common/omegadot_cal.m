classdef omegadot_cal < handle
% 角加速度计算

    properties
        dt    %采样周期
        K1    %K1系数
        K2    %K2系数
        V     %角加速度
        X     %角速度
    end
    
    methods
        % 构造函数
        function obj = omegadot_cal(dt, n)
            % dt:采样周期,s
            % n:数据维数
            obj.dt = dt;
            [obj.K1, obj.K2] = order2LoopCoefD(8, 0.707, dt);
            obj.V = zeros(1,n);
            obj.X = zeros(1,n);
        end
        
        % 运行函数
        function wdot = run(obj, w)
            E = w - obj.X;
            obj.V = obj.V + obj.K2*E;
            obj.X = obj.X + (obj.V+obj.K1*E)*obj.dt;
            wdot = obj.V;
        end
        
    end %end methods
    
end %end classdef