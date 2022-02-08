function set_coherentTime(obj, Tms)
% 设置相干积分时间
% 相干积分时间长锁相环可能出现错误的频率锁定
% 错误锁定频率为相干积分时间对应的频率除以2
% 对于20ms积分时间,可能锁在频率误差25Hz处
% 解释为半圈的cos积分为正数,半圈的sin积分为0,鉴相器输出为0

% 必须在刚跟踪完一个比特后才能改变相干积分时间
if obj.trackCnt~=0
    error('Set coherent time error!')
end

% 相干积分时间取值范围
if sum([1,2,4,5,10,20]==Tms)~=1
    error('Coherent time is invalid!')
end

Ts = Tms / 1000;

obj.coherentCnt = 0;
obj.coherentN = Tms;
obj.coherentTime = Ts;

% 调整码鉴相器方差计算系数
obj.varCoef(3) = 9e4 / (0.008*Tms);
obj.varCoef(5) = 12.67 / Tms;
obj.varCoef(6) = 500 / Tms;

% 调整二阶锁相环系数
if obj.carrMode==2 || obj.carrMode==3
    Bn = obj.PLL2(3); %带宽不变
    [K1, K2] = order2LoopCoefD(Bn, 0.707, Ts);
    obj.PLL2(1:2) = [K1, K2];
end

% 调整三阶锁相环系数
if obj.carrMode==4 || obj.carrMode==5
    Bn = obj.PLL3(4);
    [K1, K2, K3] = order3LoopCoefD(Bn, Ts);
    obj.PLL3(1:3) = [K1, K2, K3];
end

% 调整二阶码环系数
if obj.codeMode==1
    Bn = obj.DLL2(3); %带宽不变
    [K1, K2] = order2LoopCoefD(Bn, 0.707, Ts);
    obj.DLL2(1:2) = [K1, K2];
end

end