function track(obj, dataI, dataQ, deltaFreq)
% 跟踪卫星信号
% dataI,dataQ:原始数据,行向量
% deltaFreq:接收机时钟频率误差,无量纲,钟快为正
% 因为B1C捕获时获得的载波频率精度高,所以开始时不需要做频率牵引

pi2 = 2*pi;

% 存储跟踪结果(本次跟踪开始时的数据)
obj.ns = obj.ns+1; %指向当前存储行
n = obj.ns;
obj.storage.dataIndex(n)    = obj.dataIndex;
obj.storage.remCodePhase(n) = obj.remCodePhase;
obj.storage.codeFreq(n)     = obj.codeFreq;
obj.storage.remCarrPhase(n) = obj.remCarrPhase;
obj.storage.carrFreq(n)     = obj.carrFreq;
obj.storage.carrNco(n)      = obj.carrNco;
obj.storage.carrAcc(n)      = obj.carrAccS + obj.carrAccR;

% 指向下次更新的开始点
obj.dataIndex = obj.dataIndex + obj.trackBlockSize;

% 校正采样频率
fs = obj.sampleFreq * (1+deltaFreq);

% 时间序列
dts = 1/fs; %采样时间间隔
t = (0:obj.trackBlockSize-1) * dts;
te = obj.trackBlockSize * dts;

% 本地载波
theta = (obj.remCarrPhase + obj.carrNco*t) * pi2;
carr_cos = cos(theta);
carr_sin = sin(theta);
theta_next = obj.remCarrPhase + obj.carrNco*te;
obj.remCarrPhase = mod(theta_next, 1); %剩余载波相位,周

% 本地码
tcode = obj.remCodePhase + obj.codeNco*t + 2; %加2保证求滞后码时大于1
codeE = obj.codePilot(floor(tcode+0.3)); %超前码
codeP = obj.codePilot(floor(tcode));     %即时码
codeL = obj.codePilot(floor(tcode-0.3)); %滞后码
obj.remCodePhase = mod(obj.remCodePhase + obj.codeNco*te, 20460); %剩余码相位,码片

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

% 数据分量积分值
codeDP = obj.codeData(floor(tcode));
obj.Id = -signalQ * codeDP; %当导频分量与x轴正向重合时,数据分量沿y轴反向
obj.Ip = I_P;

% 码鉴相器
S_E = sqrt(I_E^2+Q_E^2);
S_L = sqrt(I_L^2+Q_L^2);
codeError = (11/30) * (S_E-S_L)/(S_E+S_L); %实际码减本地码,单位:码片,一个子载波算一个码片

% 载波鉴相器
if obj.carrDiscFlag==0
    carrError = atan(Q_P/I_P) / pi2; %实际相位减本地相位,单位:周
else
    s = obj.codeSub(obj.subPhase); %子码符号
    carrError = atan2(Q_P*s,I_P*s) / pi2; %四象限反正切鉴相器
end

% 鉴频器
yc = obj.I*I_P + obj.Q*Q_P; %I0*I1+Q0*Q1
ys = obj.I*Q_P - obj.Q*I_P; %I0*Q1-Q0*I1
freqError = atan(ys/yc)/obj.timeIntS / pi2; %实际频率减本地频率,单位:Hz
obj.I = I_P;
obj.Q = Q_P;

% 载波跟踪
switch obj.carrMode
    case 1 %锁相环
        order2PLL(carrError);
end

% 码跟踪
switch obj.codeMode
    case 1 %延迟锁定环
        order2DLL(codeError);
end

% 更新目标码相位,导频子码相位,伪码周期时间
if obj.codeTarget==20460
    obj.codeTarget = obj.timeIntMs * 2046;
    obj.subPhase = mod(obj.subPhase,1800) + 1; %导频子码相位加1(只有帧同步后确定了导频子码相位才有意义)
    obj.tc0 = obj.tc0 + 10; %一个伪码周期10ms
else
    obj.codeTarget = obj.codeTarget + obj.timeIntMs*2046; %跟踪目标码相位
end

% 更新下一数据块位置
obj.trackDataTail = obj.trackDataHead + 1;
if obj.trackDataTail>obj.buffSize
    obj.trackDataTail = 1;
end
obj.trackBlockSize = ceil((obj.codeTarget-obj.remCodePhase)/obj.codeNco*fs);
obj.trackDataHead = obj.trackDataTail + obj.trackBlockSize - 1;
if obj.trackDataHead>obj.buffSize
    obj.trackDataHead = obj.trackDataHead - obj.buffSize;
end

% 存储跟踪结果(本次跟踪产生的数据)
obj.storage.I_Q(n,:) = [I_P, I_E, I_L, Q_P, Q_E, Q_L, obj.Id, obj.Ip];
obj.storage.disc(n,:) = [codeError/2, carrError, freqError]; %码相位误差除以2,换算成主码相位误差

    %% 频率牵引
    
    %% 二阶锁相环
    function order2PLL(carrError)
        % PLL2 = [K1, K2]
        carrAcc = obj.carrAccS + obj.carrAccR;
        obj.carrFreq = obj.carrFreq + obj.PLL2(2)*carrError + carrAcc*obj.timeIntS;
        obj.carrNco = obj.carrFreq + obj.PLL2(1)*carrError;
    end
    
    %% 二阶延迟锁定环
    function order2DLL(codeError)
        % DLL2 = [K1, K2]
        obj.codeFreq = obj.codeFreq + obj.DLL2(2)*codeError;
        obj.codeNco = obj.codeFreq + obj.DLL2(1)*codeError;
    end

end