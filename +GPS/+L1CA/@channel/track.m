function track(obj, dataI, dataQ, deltaFreq)
% 跟踪卫星信号
% dataI,dataQ:原始数据,行向量
% deltaFreq:接收机时钟频率误差,无量纲,钟快为正

pi2 = 2*pi;

% 存储跟踪结果(本次跟踪开始时的数据)
obj.ns = obj.ns+1; %指向当前存储行
n = obj.ns;
obj.storage.dataIndex(n)    = obj.dataIndex;
obj.storage.remCodePhase(n) = obj.remCodePhase;
obj.storage.codeFreq(n)     = obj.codeFreq;
obj.storage.remCarrPhase(n) = obj.remCarrPhase;
obj.storage.carrFreq(n)     = obj.carrFreq;

% 指向下次更新的开始点
obj.dataIndex = obj.dataIndex + obj.trackBlockSize;

% 校正采样频率
fs = obj.sampleFreq * (1+deltaFreq);

% 时间序列
t = (0:obj.trackBlockSize-1) / fs;
te = obj.trackBlockSize / fs;

% 本地载波
theta = (obj.remCarrPhase + obj.carrNco*t) * pi2; %乘2因为后面是以pi为单位求三角函数
carr_cos = cos(theta);
carr_sin = sin(theta);
theta_next = obj.remCarrPhase + obj.carrNco*te;
obj.remCarrPhase = mod(theta_next, 1); %剩余载波相位,周

% 本地码
tcode = obj.remCodePhase + obj.codeNco*t + 2; %加2保证求滞后码时大于1
codeE = obj.code(floor(tcode+0.3)); %超前码
codeP = obj.code(floor(tcode));     %即时码
codeL = obj.code(floor(tcode-0.3)); %滞后码
obj.remCodePhase = obj.remCodePhase + obj.codeNco*te - obj.codeInt; %剩余载波相位,周

% 原始数据乘载波
signalI = dataI.*carr_cos + dataQ.*carr_sin; %乘负载波
signalQ = dataQ.*carr_cos - dataI.*carr_sin;

% 六路积分
I_E = signalI * codeE;
Q_E = signalQ * codeE;
I_P = signalI * codeP;
Q_P = signalQ * codeP;
I_L = signalI * codeL;
Q_L = signalQ * codeL;

% 码鉴相器
S_E = sqrt(I_E^2+Q_E^2);
S_L = sqrt(I_L^2+Q_L^2);
codeError = 0.7 * (S_E-S_L)/(S_E+S_L); %实际码减本地码,单位:码片
% 0.5--0.5,0.4--0.6,0.3--0.7,0.25--0.75

% 载波鉴相器
carrError = atan(Q_P/I_P) / pi2; %实际相位减本地相位,单位:周

% 鉴频器
yc = obj.I*I_P + obj.Q*Q_P; %I0*I1+Q0*Q1
ys = obj.I*Q_P - obj.Q*I_P; %I0*Q1-Q0*I1
freqError = atan(ys/yc)/obj.timeIntS / pi2; %实际频率减本地频率,单位:Hz
obj.I = I_P;
obj.Q = Q_P;

% 载波跟踪
switch obj.carrMode
    case 0
    case 1 %频率牵引
        freqPull(freqError);
    case 2 %锁相环
        order2PLL(carrError);
end

% 码跟踪
switch obj.codeMode
    case 0
    case 1 %延迟锁定环
        order2DLL(codeError);
end

% 更新伪码时间
obj.tc0 = obj.tc0 + obj.timeIntMs;

% 更新下一数据块位置
obj.trackDataTail = obj.trackDataHead + 1;
if obj.trackDataTail>obj.buffSize
    obj.trackDataTail = 1;
end
obj.trackBlockSize = ceil((obj.codeInt-obj.remCodePhase)/obj.codeNco*fs);
obj.trackDataHead = obj.trackDataTail + obj.trackBlockSize - 1;
if obj.trackDataHead>obj.buffSize
    obj.trackDataHead = obj.trackDataHead - obj.buffSize;
end

% 存储跟踪结果(本次跟踪产生的数据)
obj.storage.I_Q(n,:) = [I_P, I_E, I_L, Q_P, Q_E, Q_L];
obj.storage.disc(n,:) = [codeError, carrError, freqError];

    %% 频率牵引
    function freqPull(freqError)
        % 运行一段时间锁频环,到时间后自动进入锁相环
        obj.FLL.Int = obj.FLL.Int + obj.FLL.K*freqError;
        obj.carrNco = obj.FLL.Int;
        obj.carrFreq = obj.FLL.Int;
        obj.FLL.cnt = obj.FLL.cnt + 1; %计数
        if obj.FLL.cnt==200
            obj.FLL.cnt = 0;
            obj.PLL.Int = obj.FLL.Int; %锁相环积分器初值
            obj.carrMode = 2; %转到锁相环
            log_str = sprintf('Start PLL tracking at %.8fs', obj.dataIndex/obj.sampleFreq);
            obj.log = [obj.log; string(log_str)];
        end
    end

    %% 二阶锁相环
    function order2PLL(carrError)
        obj.PLL.Int = obj.PLL.Int + obj.PLL.K2*carrError;
        obj.carrNco = obj.PLL.Int + obj.PLL.K1*carrError;
        obj.carrFreq = obj.PLL.Int;
    end

    %% 二阶延迟锁定换
    function order2DLL(codeError)
        obj.DLL.Int = obj.DLL.Int + obj.DLL.K2*codeError;
        obj.codeNco = obj.DLL.Int + obj.DLL.K1*codeError;
        obj.codeFreq = obj.DLL.Int;
    end

end