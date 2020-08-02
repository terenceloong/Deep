function init(obj, acqResult, n)
% 初始化跟踪参数
% acqResult:捕获结果,[码相位,载波频率,峰值比值]
% n:已经经过了多少个采样点,用于计算采样点索引

% 记录捕获信息
log_str = sprintf('Acquired at %ds, peakRatio=%.2f', n/obj.sampleFreq, acqResult(3));
obj.log = [obj.log; string(log_str)];

% 激活通道
obj.state = 1;

% 本地码发生器用的码
% 列向量,前后各补一个数
code = BDS.B1C.codeGene_data(obj.PRN);
code = reshape([code;-code],10230*2,1);
obj.codeData = [code(end);code;code(1)]; %列向量
code = BDS.B1C.codeGene_pilot(obj.PRN);
code = reshape([code;-code],10230*2,1);
obj.codePilot = [code(end);code;code(1)]; %列向量
obj.codeSub = BDS.B1C.codeGene_sub(obj.PRN); %行向量

% 设置积分时间,开始是1ms
obj.timeIntMs = 1;
obj.timeIntS = 0.001;
obj.pointInt = 10;
obj.codeTarget = 2046;
obj.subPhase = 1;
obj.carrDiscFlag = 0;

% 确定数据缓存数据段
obj.trackDataTail = obj.sampleFreq*0.01 - acqResult(1) + 2;
obj.trackBlockSize = obj.sampleFreq*0.001; %初始是1ms积分时间
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

% 初始化I/Q,鉴频器用到
obj.I = 1;
obj.Q = 1;
obj.Id = 0;
obj.Ip = 0;

% 初始化FLLp
% 暂时不用锁频环

% 初始化PLL2
[K1, K2] = order2LoopCoefD(25, 0.707, obj.timeIntS);
obj.PLL2 = [K1, K2];

% 初始化DLL2
[K1, K2] = order2LoopCoefD(2, 0.707, obj.timeIntS);
obj.DLL2 = [K1, K2];

% 初始化跟踪模式
obj.carrMode = 1;
obj.codeMode = 1;

% 初始化伪码时间
obj.tc0 = NaN;

% 初始化电文解析参数
obj.msgStage = 'I';
obj.msgCnt = 0;
obj.Ip0 = 0;
obj.bitSyncTable = zeros(1,10); %一个比特持续10ms
obj.bitBuff = zeros(1,10); %最多用10个
obj.frameBuff = zeros(1,1800); %一帧数据1800比特
obj.frameBuffPtr = 0;

end