function track(obj, dataI, dataQ, deltaFreq)
% 跟踪卫星信号,每1ms执行一次
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
codeE = obj.code(floor(tcode+0.3)); %超前码
codeP = obj.code(floor(tcode));     %即时码
codeL = obj.code(floor(tcode-0.3)); %滞后码
obj.remCodePhase = obj.remCodePhase + obj.codeNco*te - 1023; %剩余码相位,码片

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

% 相干累加
if obj.coherentCnt==0
    obj.I0 = obj.I_Q(1); %记录上次I/Q值
    obj.Q0 = obj.I_Q(4);
    obj.I_Q = I_Q_1ms; %首次直接赋值
else
    obj.I_Q = obj.I_Q + I_Q_1ms;
end
obj.coherentCnt = obj.coherentCnt + 1;

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
    
    % 码鉴相器 (0.5--0.5,0.4--0.6,0.3--0.7,0.25--0.75)
    S_E = sqrt(I_E^2+Q_E^2);
    S_L = sqrt(I_L^2+Q_L^2);
    codeError = 0.7 * (S_E-S_L)/(S_E+S_L); %实际码减本地码,单位:码片
    
    % 载波鉴相器
    carrError = atan(Q_P/I_P) / pi2; %实际相位减本地相位,单位:周
    
    % 鉴频器
    yc = obj.I0*I_P + obj.Q0*Q_P; %I0*I1+Q0*Q1
    ys = obj.I0*Q_P - obj.Q0*I_P; %I0*Q1-Q0*I1
    freqError = atan(ys/yc)/obj.coherentTime / pi2; %实际频率减本地频率,单位:Hz
    
    % 存储鉴相器输出
    obj.storage.disc(n,:) = [codeError, carrError, freqError];
    obj.codeDiscBuffPtr = obj.codeDiscBuffPtr + 1;
    obj.codeDiscBuff(obj.codeDiscBuffPtr) = codeError;
    if obj.codeDiscBuffPtr==200
        obj.codeDiscBuffPtr = 0;
    end
    
    % 载波跟踪
    switch obj.carrMode
        case 1 %频率牵引
            freqPull(freqError);
        case 2 %锁相环
            order2PLL(carrError);
        case 3 %深组合锁相环
            deepPLL(carrError);
    end
    
    % 码跟踪
    switch obj.codeMode
        case 1 %延迟锁定环
            order2DLL(codeError);
        case 2 %码开环
            openDLL(deltaFreq);
    end
end

% 更新伪码时间
obj.tc0 = obj.tc0 + 1; %加1ms

% 更新下一数据块位置
obj.trackDataTail = obj.trackDataHead + 1;
if obj.trackDataTail>obj.buffSize
    obj.trackDataTail = 1;
end
obj.trackBlockSize = ceil((1023-obj.remCodePhase)/obj.codeNco*fs);
obj.trackDataHead = obj.trackDataTail + obj.trackBlockSize - 1;
if obj.trackDataHead>obj.buffSize
    obj.trackDataHead = obj.trackDataHead - obj.buffSize;
end

% 累积比特,计算载噪比
obj.trackCnt = obj.trackCnt + 1;
if obj.bitSyncFlag==1 %完成比特同步
    obj.IpBuff(obj.trackCnt) = IP_1ms;
    obj.QpBuff(obj.trackCnt) = QP_1ms;
    if obj.trackCnt==20 %跟踪完1个比特
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
        %----长时间失锁关闭通道(深组合时不关)
        if obj.lossCnt>5 && obj.state~=3
            obj.state = 0;
            obj.ns = obj.ns + 1; %数据存储跳一个,相当于加一个间断点
            log_str = sprintf('***Loss of lock at %.8fs', obj.dataIndex/obj.sampleFreq);
            obj.log = [obj.log; string(log_str)];
        end
    end %end 跟踪完一个比特
end

% 存储跟踪结果(本次跟踪产生的数据)
obj.storage.I_Q(n,:) = I_Q_1ms; %1ms的I/Q数据
obj.storage.CN0(n) = obj.CN0;

    %% 频率牵引
	function freqPull(freqError)
        % 运行一段时间锁频环,到时间后自动进入锁相环
        % FLLp = [K, cnt]
        obj.carrFreq = obj.carrFreq + obj.FLLp(1)*freqError;
        obj.carrNco = obj.carrFreq;
        obj.FLLp(2) = obj.FLLp(2) + 1; %计数
        if obj.FLLp(2)==200
            obj.FLLp(2) = 0;
            obj.carrMode = 2; %转到锁相环
            log_str = sprintf('Start PLL tracking at %.8fs', obj.dataIndex/obj.sampleFreq);
            obj.log = [obj.log; string(log_str)];
        end
    end

    %% 二阶锁相环
    function order2PLL(carrError)
        % 卫星运动引起的载波频率变化率总是负的,大约是-0.3~-0.6Hz/s
        % 如果不加前馈,测的载波频率偏大,大约0.01Hz~0.02Hz
        % 验证加前馈的效果看载波鉴相器均值,加完前馈均值会更接近0
        % PLL2 = [K1, K2, Bn]
        carrAcc = obj.carrAccS + obj.carrAccR; %载波加速度前馈
        obj.carrFreq = obj.carrFreq + obj.PLL2(2)*carrError + carrAcc*obj.coherentTime; %积分器是载波频率估计值
        %----调频调相
%         obj.carrNco = obj.carrFreq + obj.PLL2(1)*carrError;
        %----直接调相
        obj.carrNco = obj.carrFreq;
        obj.remCarrPhase = obj.remCarrPhase + obj.PLL2(1)*carrError*obj.coherentTime;
    end

    %% 深组合锁相环
    function deepPLL(carrError)
        % PLL2 = [K1, K2, Bn]
        % 估计频率靠二阶环路估计,驱动频率靠外部更新
        % 参见程序track_sim.m
        dt = obj.coherentTime; %时间间隔
        fi = (obj.carrAccS+obj.carrAccR) * dt; %载波加速度引起的频率增量
        obj.carrFreq = obj.carrFreq + fi;
        obj.carrNco = obj.carrNco + fi;
        df = obj.carrNco - obj.carrFreq;
        dp = -carrError - df*dt;
        obj.remCarrPhase = obj.remCarrPhase - df*dt - obj.PLL2(1)*dt*dp; %alpha=K1*dt
        obj.carrFreq = obj.carrFreq - obj.PLL2(2)*dp; %beta=K2
        if obj.CN0<37
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
    function openDLL(deltaFreq)
        % 码频率由载波频率直接驱动
        % 直接测的载波频率包含接收机钟频差
        % 接收机钟快,测的载波频率偏小,需要加上,得到实际的载波频率
        % 接收的码频率不受接收机钟频差的影响,因为钟频差主要影响下变频,对调制信号没有影响
        carrFreq = obj.carrFreq + deltaFreq*1575.42e6;
        obj.codeNco = 1.023e6 + carrFreq/1540;
        obj.codeFreq = obj.codeNco;
    end

end