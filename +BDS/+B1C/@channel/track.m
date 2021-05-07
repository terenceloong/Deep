function track(obj, dataI, dataQ)
% 跟踪卫星信号,每1ms执行一次
% dataI,dataQ:原始数据,行向量
% 因为B1C捕获时获得的载波频率精度高,所以开始时不需要做频率牵引

pi2 = 2*pi;

% 存储行号
obj.ns = obj.ns+1; %指向当前存储行
n = obj.ns;

% 指向下次更新的开始点
obj.dataIndex = obj.dataIndex + obj.trackBlockSize;

% 时间序列
t = obj.Tseq(1:obj.trackBlockSize);
te = obj.Tseq(obj.trackBlockSize+1);

% 本地载波
theta = (obj.remCarrPhase + obj.carrNco*t) * pi2;
carr_cos = cos(theta);
carr_sin = sin(theta);
theta_next = obj.remCarrPhase + obj.carrNco*te;
obj.remCarrPhase = mod(theta_next, 1); %剩余载波相位,周

% 本地码
tcode = obj.remCodePhase + obj.codeNco*t + 2; %加2保证求滞后码时大于1
index = floor(tcode);
codeE = obj.codePilot(floor(tcode+0.3)); %超前码
codeP = obj.codePilot(index);            %即时码
codeL = obj.codePilot(floor(tcode-0.3)); %滞后码
obj.remCodePhase = obj.remCodePhase + obj.codeNco*te; %剩余码相位,码片
obj.remCodePhase = mod(obj.remCodePhase+1,20460)-1; %防止剩余码相位略小于20460,导致算trackBlockSize时出现负数

% 原始数据乘载波
signalI = dataI.*carr_cos + dataQ.*carr_sin; %乘负载波
signalQ = dataQ.*carr_cos - dataI.*carr_sin;

% 六路积分
IE_1ms = signalI * codeE;
QE_1ms = signalQ * codeE;
IP_1ms = signalI * codeP;
QP_1ms = signalQ * codeP;
IL_1ms = signalI * codeL;
QL_1ms = signalQ * codeL;
I_Q_1ms = [IP_1ms, IE_1ms, IL_1ms, QP_1ms, QE_1ms, QL_1ms];
if obj.carrDiscFlag==1 %确定子码相位后调整积分值的符号
    I_Q_1ms = I_Q_1ms * obj.codeSub(obj.subPhase);
end

% 数据分量积分值
codeDP = obj.codeData(index);
Id = -signalQ * codeDP; %当导频分量与x轴正向重合时,数据分量沿y轴反向

% 相干累加
if obj.coherentCnt==0
    obj.I0 = obj.I_Q(1); %记录上次I/Q值
    obj.Q0 = obj.I_Q(4);
    obj.I_Q = I_Q_1ms; %首次直接赋值
else
    obj.I_Q = obj.I_Q + I_Q_1ms;
end
obj.coherentCnt = obj.coherentCnt + 1;

% 更新码和载波的频率(用载波加速度驱动,用来适应长积分时间的情况)
dCarrFreq = (obj.carrAccS+obj.carrAccR) * 0.001; %载波频率增量
obj.carrFreq = obj.carrFreq + dCarrFreq;
obj.carrNco = obj.carrNco + dCarrFreq;
dCodeFreq = dCarrFreq / 770; %码频率增量
obj.codeFreq = obj.codeFreq + dCodeFreq;
obj.codeNco = obj.codeNco + dCodeFreq;

% 相干积分时间到了
if obj.coherentCnt==obj.coherentN
    obj.coherentCnt = 0; %清计数
    
    % 提取六路I/Q数据
    I_P = obj.I_Q(1);
    I_E = obj.I_Q(2);
    I_L = obj.I_Q(3);
    Q_P = obj.I_Q(4);
    Q_E = obj.I_Q(5);
    Q_L = obj.I_Q(6);
    
    % 码鉴相器
    S_E = sqrt(I_E^2+Q_E^2);
    S_L = sqrt(I_L^2+Q_L^2);
    codeError = (11/30) * (S_E-S_L)/(S_E+S_L); %实际码减本地码,单位:码片,一个子载波算一个码片
    
    % 载波鉴相器
    if obj.carrDiscFlag==0
        carrError = atan(Q_P/I_P) / pi2; %实际相位减本地相位,单位:周
    else
        carrError = atan2(Q_P,I_P) / pi2; %四象限反正切鉴相器
    end
    
    % 鉴频器
    yc = obj.I0*I_P + obj.Q0*Q_P; %I0*I1+Q0*Q1
    ys = obj.I0*Q_P - obj.Q0*I_P; %I0*Q1-Q0*I1
    freqError = atan(ys/yc)/obj.coherentTime / pi2; %实际频率减本地频率,单位:Hz
    
    % 存储鉴相器输出
    obj.storage.disc(n,:) = [codeError/2, carrError, freqError]; %码相位误差除以2,换算成主码相位误差
    obj.codeDiscBuffPtr = obj.codeDiscBuffPtr + 1;
    obj.codeDiscBuff(obj.codeDiscBuffPtr) = codeError/2; %主码相位误差
    if obj.codeDiscBuffPtr==200
        obj.codeDiscBuffPtr = 0;
    end
    
    % 载波跟踪
    switch obj.carrMode
        case 2 %二阶锁相环
            order2PLL(carrError);
        case 3 %矢量二阶锁相环
            vectorPLL2(carrError);
    end
    
    % 码跟踪
    switch obj.codeMode
        case 1 %二阶延迟锁定环
            order2DLL(codeError);
        case 2 %码开环
            openDLL;
    end
end

% 更新目标码相位,导频子码相位,伪码周期时间
if obj.codeTarget==20460
    obj.codeTarget = 2046;
    obj.subPhase = mod(obj.subPhase,1800) + 1; %导频子码相位加1(只有帧同步后确定了导频子码相位才有意义)
    obj.tc0 = obj.tc0 + 10; %一个伪码周期10ms
else
    obj.codeTarget = obj.codeTarget + 2046; %跟踪目标码相位
end

% 更新下一数据块位置
obj.trackDataTail = obj.trackDataHead + 1;
if obj.trackDataTail>obj.buffSize
    obj.trackDataTail = 1;
end
obj.trackBlockSize = ceil((obj.codeTarget-obj.remCodePhase)/obj.codeNco*obj.sampleFreq);
obj.trackDataHead = obj.trackDataTail + obj.trackBlockSize - 1;
if obj.trackDataHead>obj.buffSize
    obj.trackDataHead = obj.trackDataHead - obj.buffSize;
end

% 累积比特,计算载噪比
obj.trackCnt = obj.trackCnt + 1;
if obj.bitSyncFlag==1 %完成比特同步
    obj.IpBuff(obj.trackCnt) = IP_1ms;
    obj.QpBuff(obj.trackCnt) = QP_1ms;
    obj.IdBuff(obj.trackCnt) = Id;
    if obj.trackCnt==10 %跟踪完1个比特
        obj.trackCnt = 0; %清计数器
        %----记录比特边界标志
        obj.storage.bitFlag(n) = obj.msgStage; %比特结束的位置
        %----计算载噪比
        obj.CN0 = obj.CNR.cal(obj.IpBuff, obj.QpBuff);
        %----调整积分时间
        obj.adjust_coherentTime(2);
        %----计算噪声方差
        obj.varValue = obj.varCoef / 10^(obj.CN0/10);
        %----信号失锁计数
        if obj.CN0<18
            obj.lossCnt = obj.lossCnt + 1;
        else
            obj.lossCnt = 0;
        end
        %----长时间失锁关闭通道(矢量跟踪时不关)
        if obj.lossCnt>5 && obj.state~=3
            obj.state = 0;
            obj.ns = obj.ns + 1; %数据存储跳一个,相当于加一个间断点
            log_str = sprintf('***Loss of lock at %.8fs', obj.dataIndex/obj.sampleFreq);
            obj.log = [obj.log; string(log_str)];
        end
    end %end 跟踪完一个比特
end

% 存储跟踪结果
obj.storage.dataIndex(n) = obj.dataIndex;
obj.storage.remCodePhase(n) = obj.remCodePhase;
obj.storage.codeFreq(n) = obj.codeFreq;
obj.storage.remCarrPhase(n) = obj.remCarrPhase;
obj.storage.carrFreq(n) = obj.carrFreq;
obj.storage.carrNco(n) = obj.carrNco;
obj.storage.carrAcc(n) = obj.carrAccS + obj.carrAccR;
obj.storage.I_Q(n,:) = [IP_1ms, IE_1ms, IL_1ms, QP_1ms, QE_1ms, QL_1ms, Id, IP_1ms];
% obj.storage.I_Q(n,:) = [I_Q_1ms, Id, IP_1ms]; %剥离数据的
obj.storage.CN0(n) = obj.CN0;

    %% 二阶锁相环
    function order2PLL(carrError)
        % PLL2 = [K1, K2, Bn]
        obj.carrFreq = obj.carrFreq + obj.PLL2(2)*carrError; %积分器是载波频率估计值
        %----调频调相
%         obj.carrNco = obj.carrFreq + obj.PLL2(1)*carrError;
        %----直接调相
        obj.carrNco = obj.carrFreq;
        obj.remCarrPhase = obj.remCarrPhase + obj.PLL2(1)*carrError*obj.coherentTime;
    end

    %% 矢量二阶锁相环
    function vectorPLL2(carrError)
        % PLL2 = [K1, K2, Bn]
        % 估计频率靠二阶环路估计,驱动频率靠外部更新
        dt = obj.coherentTime; %时间间隔
        df = obj.carrFreq - obj.carrNco;
        dp = carrError - df*dt;
        obj.remCarrPhase = obj.remCarrPhase + df*dt + obj.PLL2(1)*dt*dp; %alpha=K1*dt
        obj.carrFreq = obj.carrFreq + obj.PLL2(2)*dp; %beta=K2
        if obj.CN0<37 %不是强信号不对载波频率进行估计,弱信号转为强信号相当于重启锁相环
            obj.carrFreq = obj.carrNco;
        end
    end

    %% 二阶延迟锁定环
    function order2DLL(codeError)
        % DLL2 = [K1, K2, Bn]
        obj.codeFreq = obj.codeFreq + obj.DLL2(2)*codeError;
        %----调频调相
%         obj.codeNco = obj.codeFreq + obj.DLL2(1)*codeError;
        %----直接调相
        obj.codeNco = obj.codeFreq;
        obj.remCodePhase = obj.remCodePhase + obj.DLL2(1)*codeError*obj.coherentTime;
    end

    %% 码开环
    function openDLL
        obj.codeNco = (1.023e6 + obj.carrFreq/1540) * 2; %因为有子载波,要乘2
        obj.codeFreq = obj.codeNco;
    end

end