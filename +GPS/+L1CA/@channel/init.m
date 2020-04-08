function init(obj, acqResult, n)
% 初始化跟踪参数
% acqResult:捕获结果,[码相位,载波频率,峰值比值]
% n:已经经过了多少个采样点,用于计算采样点索引

% 记录捕获信息
log_str = sprintf('Acquired at %ds, peakRatio=%.2f', n/obj.sampleFreq, acqResult(3));
obj.log = [obj.log; string(log_str)];

% 激活通道
obj.state = 1;

% 本地本地码发生器用的C/A码
% 列向量,方便后面用矩阵乘法代替累加求和
% 前后各补一个数,方便取超前滞后码
% 当积分时间改变时,code要变成对应的长度
obj.code = [obj.CAcode(end),obj.CAcode,obj.CAcode(1)]';

% 设置积分时间,开始是1ms
obj.timeIntMs = 1;
obj.timeIntS = 0.001;
obj.codeInt = 1023;
obj.pointInt = 20;

% 确定数据缓存数据段
obj.trackDataTail = obj.sampleFreq*0.001 - acqResult(1) + 2;
obj.trackBlockSize = obj.sampleFreq*0.001; %0.001表示1ms积分时间
obj.trackDataHead = obj.trackDataTail + obj.trackBlockSize - 1;
obj.dataIndex = obj.trackDataTail + n;

% 初始化本地信号发生器
obj.carrAcc = 0;
obj.carrNco = acqResult(2);
obj.codeNco = 1.023e6 + obj.carrNco/1540;
obj.remCarrPhase = 0;
obj.remCodePhase = 0;
obj.carrFreq = obj.carrNco;
obj.codeFreq = obj.codeNco;

% 初始化I/Q,鉴频器用到
obj.I = 1;
obj.Q = 1;

% 初始化FLLp
K = 40 * obj.timeIntS;
Int = obj.carrNco; %积分器
cnt = 0; %计数器
obj.FLLp = [K, Int, cnt];

% 初始化PLL2
[K1, K2] = order2LoopCoefD(25, 0.707, obj.timeIntS);
Int = 0; %积分器
obj.PLL2 = [K1, K2, Int];

% 初始化DLL2
[K1, K2] = order2LoopCoefD(2, 0.707, obj.timeIntS);
Int = obj.codeNco; %积分器
obj.DLL2 = [K1, K2, Int];

% 初始化跟踪模式
obj.carrMode = 1;
obj.codeMode = 1;

% 初始信号质量
obj.quality = 2;

% 初始化伪码时间
obj.tc0 = NaN;

% 初始化电文解析参数
obj.msgStage = 'I';
obj.msgCnt = 0;
obj.I0 = 0;
obj.bitSyncTable = zeros(1,20); %一个比特持续20ms
obj.bitBuff = zeros(1,20); %最多用20个
obj.frameBuff = zeros(1,1502); %一帧数据1500比特
obj.frameBuffPtr = 0;

end