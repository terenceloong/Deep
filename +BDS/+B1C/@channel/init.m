function init(obj, acqResult, n)
% 初始化跟踪参数
% acqResult:捕获结果,[码相位,载波频率,峰值比值]
% n:已经经过了多少个采样点,用于计算采样点索引

% 记录捕获信息
log_str = sprintf('Acquired at %.2fs, peakRatio=%.2f', n/obj.sampleFreq, acqResult(3));
obj.log = [obj.log; string(log_str)];

% 激活通道
obj.state = 1;

% 设置积分时间,开始是1ms
obj.coherentCnt = 0;
obj.coherentN = 1;
obj.coherentTime = 0.001;
obj.codeTarget = 2046;
obj.subPhase = 1;
obj.carrDiscFlag = 0;

% 确定数据缓存数据段
obj.trackDataTail = obj.sampleFreq*0.01 - acqResult(1) + 2;
obj.trackBlockSize = obj.sampleFreq*0.001; %1ms的采样点数
obj.trackDataHead = obj.trackDataTail + obj.trackBlockSize - 1;
obj.dataIndex = obj.trackDataTail + n;

% 初始化本地信号发生器
obj.carrAccS = 0;
obj.carrAccR = 0;
obj.carrNco = acqResult(2);
obj.codeNco = (1.023e6 + obj.carrNco/1540) * 2; %因为有子载波,要乘2
obj.remCarrPhase = 0;
obj.remCodePhase = 0;
obj.carrFreq = obj.carrNco;
obj.codeFreq = obj.codeNco;

% 相干积分I/Q值
obj.I_Q = ones(1,6); %非零值,否则鉴频器输出有错误值
obj.I0 = 0;
obj.Q0 = 0;

% 初始化FLLp
% 暂时不用锁频环

% 初始化PLL2
[K1, K2] = order2LoopCoefD(25, 0.707, 0.001);
obj.PLL2 = [K1, K2, 25];

% 初始化DLL2
[K1, K2] = order2LoopCoefD(2, 0.707, 0.001);
obj.DLL2 = [K1, K2, 2];

% 初始化跟踪模式
obj.carrMode = 2; %直接进锁相环
obj.codeMode = 1;

% 初始化码鉴相器输出缓存
obj.codeDiscBuff = zeros(1,200);
obj.codeDiscBuffPtr = 0;

% 初始化噪声方差
% 所有噪声的方差都与1/10^(CN0/10)成正比
% 静止时是比较小的系数,动起来系数可以放大
obj.varCoef = zeros(1,3);
obj.varCoef(1) = (0.08*obj.DLL2(3)) * 9e4;
obj.varCoef(2) = (0.32*obj.PLL2(3))^3 * 0.0363;
obj.varCoef(3) = 9e4 / 0.072; %码鉴相器标准差是GPS C/A码的1/3
obj.varValue = zeros(1,3);

% 初始化伪码时间
obj.tc0 = NaN;

% 初始化载噪比计算
obj.CNR = CNR_NWPR(10, 40); %400ms
obj.CN0 = 0;
obj.lossCnt = 0;

% 初始化比特累积控制
obj.trackCnt = 0;
obj.IpBuff = zeros(1,10);
obj.QpBuff = zeros(1,10);
obj.IdBuff = zeros(1,10);
obj.bitSyncFlag = 0;
obj.bitSyncTable = zeros(1,10);

% 初始化电文解析参数
obj.msgStage = 'I';
obj.frameBuff = zeros(1,1800); %一帧数据1800比特
obj.frameBuffPtr = 0;

end