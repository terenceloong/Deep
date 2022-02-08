classdef channel < handle
% 北斗B1C信号跟踪通道
% state:通道状态, 0-未激活, 1-已激活但没有星历, 2-可以进行伪距伪距率测量, 3-矢量跟踪

    properties
        Tms             %总运行时间,ms,用来确定画图的横坐标
        sampleFreq      %标称采样频率,Hz
        buffSize        %数据缓存总采样点数
        PRN             %卫星编号
        state           %通道状态
        acqN            %捕获采样点数
        acqThreshold    %捕获阈值,最高峰与第二大峰的比值
        acqFreq         %搜索频率范围
        acqM            %搜索频率个数
        CODE            %捕获用的导频主码的FFT(含子载波,前面补零)
        codeData        %本地码发生器数据主码(含子载波)
        codePilot       %本地码发生器导频主码(含子载波)
        codeSub         %本地码发生器导频子码
        Tseq            %本地信号发生器使用的时间序列
        coherentCnt     %相干积分计数,每1ms加1
        coherentN       %相干积分次数
        coherentTime    %相干积分时间,s
        codeTarget      %当前跟踪目标码相位
        subPhase        %当前子码相位
        carrDiscFlag    %载波鉴相器标志,0-二象限反正切鉴相器,1-四象限反正切鉴相器
        trackDataTail   %跟踪开始点在数据缓存中的位置
        trackBlockSize  %跟踪数据段采样点个数
        trackDataHead   %跟踪结束点在数据缓存中的位置
        dataIndex       %跟踪开始点在文件中的位置
        carrAccS        %卫星运动引起的载波频率变化率
        carrAccR        %接收机运动引起的载波频率变化率
        carrNco         %载波发生器驱动频率
        codeNco         %码发生器驱动频率
        remCarrPhase    %跟踪开始点的载波相位
        remCodePhase    %跟踪开始点的码相位
        carrFreq        %测量的载波频率
        codeFreq        %测量的码频率
        carrCirc        %载波相位整周数,载波相位与伪距对应
        I_Q             %当前6路相干积分I/Q值
        I0              %上次I_P积分值,用于鉴频器和比特同步
        Q0              %上次Q_P积分值
        FLLp            %频率牵引锁频环
        PLL2            %二阶锁相环
        PLL3            %三阶锁相环
        DLL2            %二阶延迟锁定环
        carrMode        %载波跟踪模式
        codeMode        %码跟踪模式
        discBuff        %鉴相器输出缓存(矢量跟踪时用到)
        discBuffPtr     %鉴相器输出缓存指针
        varCoef         %噪声方差计算系数,[伪距,伪距率,码鉴相器]
        varValue        %噪声方差值
        tc0             %下一伪码周期的开始时间,ms
        CN0Thr          %载噪比阈值,是一个handle类,与接收机共享
        CNR             %载噪比计算模块
        CN0             %载噪比值,10ms一更新
        lossCnt         %失锁计数器
        trackCnt        %跟踪计数器,每1ms加1
        IpBuff          %1个比特内的10个I路积分值(导频)
        QpBuff          %1个比特内的10个Q路积分值(导频)
        IdBuff          %1个比特内的10个I路积分值(数据)
        bitSyncFlag     %比特同步标志
        bitSyncTable    %比特同步统计表
        msgStage        %电文解析阶段(字符)
        frameBuff       %帧缓存
        frameBuffPtr    %帧缓存指针
        ephe            %星历
        iono            %电离层校正参数
        log             %日志
        ns              %指向当前存储行,初值是0,刚开始运行track时加1
        storage         %存储跟踪结果
    end
    
    methods
        function obj = channel(PRN, conf) %构造函数
            % PRN:卫星编号
            % conf:通道配置结构体
            %----设置不会变的参数
            obj.Tms = conf.Tms;
            obj.sampleFreq = conf.sampleFreq;
            obj.buffSize = conf.buffSize;
            obj.PRN = PRN;
            %----设置通道状态
            obj.state = 0;
            %----设置捕获参数
            obj.acqN = obj.sampleFreq*0.02; %取20ms的数
            obj.acqThreshold = conf.acqThreshold;
            N = obj.sampleFreq*0.01; %一个伪码周期采样点数
            obj.acqFreq = -conf.acqFreqMax:(obj.sampleFreq/N/2):conf.acqFreqMax;
            obj.acqM = length(obj.acqFreq);
            B1Ccode = BDS.B1C.codeGene_pilot(PRN); %生成B1C导频主码
            B1Ccode = reshape([B1Ccode;-B1Ccode],10230*2,1)'; %加子载波,行向量
            index = floor((0:N-1)*1.023e6*2/obj.sampleFreq) + 1; %码采样的索引
            codes = B1Ccode(index);
            code = [zeros(1,N), codes]; %前面补零
            obj.CODE = fft(code);
            %----本地码发生器用的码
            code = BDS.B1C.codeGene_data(PRN);
            code = reshape([code;-code],10230*2,1);
            obj.codeData = [code(end);code;code(1)]; %列向量
            code = BDS.B1C.codeGene_pilot(PRN);
            code = reshape([code;-code],10230*2,1);
            obj.codePilot = [code(end);code;code(1)]; %列向量
            obj.codeSub = BDS.B1C.codeGene_sub(obj.PRN); %行向量
            %----本地信号发生器使用的时间序列
            obj.Tseq = (0:obj.sampleFreq*0.001+4)/obj.sampleFreq; %多给几个点
            %----载噪比阈值
            obj.CN0Thr = conf.CN0Thr;
            %----申请星历空间
            obj.ephe = NaN(1,30);
            obj.iono = NaN(1,9);
            %----申请数据存储空间
            obj.ns = 0;
            row = obj.Tms; %存储空间行数
            obj.storage.dataIndex    =   NaN(row,1,'double'); %使用预设NaN存数据,方便通道断开时数据显示有中断
            obj.storage.remCodePhase =   NaN(row,1,'single');
            obj.storage.codeFreq     =   NaN(row,1,'double');
            obj.storage.remCarrPhase =   NaN(row,1,'single');
            obj.storage.carrFreq     =   NaN(row,1,'double');
            obj.storage.carrNco      =   NaN(row,1,'double');
            obj.storage.carrAcc      =   NaN(row,1,'single');
            obj.storage.I_Q          = zeros(row,8,'int32');
            obj.storage.disc         =   NaN(row,3,'single');
            obj.storage.CN0          =   NaN(row,1,'single');
            obj.storage.bitFlag      = zeros(row,1,'uint8'); %比特边界标志
        end
    end
    
    methods (Access = public)
        acqResult = acq(obj, dataI, dataQ)         %捕获卫星信号
        init(obj, acqResult, n)                    %初始化跟踪参数
        track(obj, dataI, dataQ)                   %跟踪卫星信号
        parse(obj)                                 %解析导航电文
        set_coherentTime(obj, Tms)                 %设置相干积分时间
        adjust_coherentTime(obj, policy)           %调整相干积分时间
        clean_storage(obj)                         %清理数据存储
        print_log(obj)                             %打印通道日志
        %----画图函数
        plot_trackResult(obj)
        plot_I_Q(obj)
        plot_I_P(obj)
        plot_I_P_flag(obj)
        plot_codeFreq(obj)
        plot_carrFreq(obj)
        plot_carrNco(obj)
        plot_carrAcc(obj)
        plot_codeDisc(obj)
        plot_carrDisc(obj)
        plot_freqDisc(obj)
        plot_quality(obj)
    end
    
end %end classdef