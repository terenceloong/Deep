function track(obj, dataI, dataQ)
% 跟踪卫星信号,每1ms执行一次
% dataI,dataQ:原始数据,行向量

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
obj.carrCirc = obj.carrCirc - floor(theta_next); %更新整周数,因为负载波对应伪距,所以是往下减

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

% 更新码和载波的频率(用载波加速度驱动,用来适应长积分时间的情况)
dCarrFreq = (obj.carrAccS+obj.carrAccR) * 0.001; %载波频率增量
obj.carrFreq = obj.carrFreq + dCarrFreq;
obj.carrNco = obj.carrNco + dCarrFreq;
dCodeFreq = dCarrFreq / 1540; %码频率增量
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
        case 2 %二阶锁相环
            order2PLL(carrError);
        case 3 %矢量二阶锁相环
            vectorPLL2(carrError);
        case 4 %三阶锁相环
            order3PLL(carrError);
        case 5 %矢量三阶锁相环
            vectorPLL3(carrError);
    end
    
    % 码跟踪
    switch obj.codeMode
        case 1 %二阶延迟锁定环
            order2DLL(codeError);
        case 2 %码开环
            openDLL;
    end
end

% 更新伪码时间
obj.tc0 = obj.tc0 + 1; %加1ms

% 更新下一数据块位置
obj.trackDataTail = obj.trackDataHead + 1;
if obj.trackDataTail>obj.buffSize
    obj.trackDataTail = 1;
end
obj.trackBlockSize = ceil((1023-obj.remCodePhase)/obj.codeNco*obj.sampleFreq);
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
        obj.adjust_coherentTime(1);
        %----计算噪声方差
        CN0n = 10^(obj.CN0/10); %正常的载噪比数值
        obj.varValue = obj.varCoef / CN0n;
        obj.varValue(4) = obj.varValue(4) * (1+obj.varValue(5));
        %----信号失锁计数
        if obj.CN0<obj.CN0Thr.loss %18
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
% obj.storage.carrAccE(n) = obj.carrAccS + obj.carrAccE;
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
            obj.carrMode = 4; %转到锁相环
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
        % 参见程序track_sim.m
        dt = obj.coherentTime; %时间间隔
        %------------------------------------------------------------------
%         df = obj.carrNco - obj.carrFreq;
%         dp = -carrError - df*dt;
%         obj.remCarrPhase = obj.remCarrPhase - df*dt - obj.PLL2(1)*dt*dp; %alpha=K1*dt
%         obj.carrFreq = obj.carrFreq - obj.PLL2(2)*dp; %beta=K2
        %------------------------------------------------------------------
        df = obj.carrFreq - obj.carrNco; %驱动频率较估计频率慢多少
        dp = carrError - df*dt; %把驱动频率慢引起的相位差刨出去
        obj.remCarrPhase = obj.remCarrPhase + df*dt + obj.PLL2(1)*dt*dp; %alpha=K1*dt,把驱动频率慢引起的相位差补偿回来
        obj.carrFreq = obj.carrFreq + obj.PLL2(2)*dp; %beta=K2
        %------------------------------------------------------------------
        if obj.CN0<obj.CN0Thr.recovery
            obj.carrFreq = obj.carrNco;
        end
    end

    %% 三阶锁相环
    function order3PLL(carrError)
        % PLL3 = [K1, K2, K3, Bn]
        obj.carrAccR = obj.carrAccR + obj.PLL3(3)*carrError; %估计的载波加速度
        obj.carrFreq = obj.carrFreq + obj.PLL3(2)*carrError;
        %----调频调相
%         obj.carrNco = obj.carrFreq + obj.PLL3(1)*carrError;
        %----直接调相
        obj.carrNco = obj.carrFreq;
        obj.remCarrPhase = obj.remCarrPhase + obj.PLL3(1)*carrError*obj.coherentTime;
    end

    %% 矢量三阶锁相环
    function vectorPLL3(carrError)
        % PLL3 = [K1, K2, K3, Bn]
        dt = obj.coherentTime; %时间间隔
        df = obj.carrFreq - obj.carrNco;
        dp = carrError - df*dt;
        obj.remCarrPhase = obj.remCarrPhase + df*dt + obj.PLL3(1)*dt*dp;
        obj.carrFreq = obj.carrFreq + obj.PLL3(2)*dp;
        obj.carrAccR = obj.carrAccR + obj.PLL3(3)*dp;
        if obj.CN0<obj.CN0Thr.recovery
            obj.carrFreq = obj.carrNco;
            obj.carrAccR = obj.carrAccE;
        else %强信号时,NCO驱动频率与估计频率保持同步
            obj.carrNco = obj.carrNco + obj.PLL3(2)*dp;
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
        % 码频率由载波频率直接驱动
        % 即便有钟频差也不用管,关系不变
        obj.codeNco = 1.023e6 + obj.carrFreq/1540;
        obj.codeFreq = obj.codeNco;
    end

end