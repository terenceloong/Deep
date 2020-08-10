classdef channel < handle
% 北斗B1C信号跟踪通道
% state:通道状态, 0-未激活, 1-已激活但没有星历, 2-可以进行伪距伪距率测量, 3-深组合

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
        timeIntMs       %积分时间,ms
        timeIntS        %积分时间,s
        pointInt        %一个比特有多少个积分点,一个比特10ms
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
        carrVar         %载波鉴相器方差计算
        codeVar         %码鉴相器方差计算
        I               %I路积分值(鉴频器用)
        Q               %Q路积分值(鉴频器用)
        Id              %数据分量积分值
        Ip              %导频分量积分值
        PLL2            %二阶锁相环
        DLL2            %二阶延迟锁定环
        carrMode        %载波跟踪模式
        codeMode        %码跟踪模式
        tc0             %下一伪码周期的开始时间,ms
        
        msgStage        %电文解析阶段(字符)
        msgCnt          %电文解析计数器
        Ip0             %上次导频分量积分值(用于比特同步)
        bitSyncTable    %比特同步统计表
        bitBuff         %比特缓存
        frameBuff       %帧缓存
        frameBuffPtr    %帧缓存指针
        ephe            %星历
        iono            %电离层校正参数
        
        log             %日志
        ns              %指向当前存储行,初值是0,刚开始运行track时加1
        storage         %存储跟踪结果
        
        quality         %信号质量
        SQI             %信号质量指示器
        ns0             %指向上次定位的存储行,深组合时用来获取定位间隔内的鉴相器输出
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
            %---申请星历空间
            obj.ephe = NaN(1,30);
            obj.iono = NaN(1,9);
            %----申请数据存储空间
            obj.ns = 0;
            obj.ns0 = 0;
            row = obj.Tms; %存储空间行数
            obj.storage.dataIndex    =   NaN(row,1,'double'); %使用预设NaN存数据,方便通道断开时数据显示有中断
            obj.storage.remCodePhase =   NaN(row,1,'single');
            obj.storage.codeFreq     =   NaN(row,1,'double');
            obj.storage.remCarrPhase =   NaN(row,1,'single');
            obj.storage.carrFreq     =   NaN(row,1,'double');
            obj.storage.carrNco      =   NaN(row,1,'double');
            obj.storage.carrAcc      =   NaN(row,1,'single');
            obj.storage.I_Q          = zeros(row,8,'int32');
            obj.storage.disc         =   NaN(row,5,'single');
            obj.storage.bitFlag      = zeros(row,1,'uint8'); %导航电文比特开始标志
            obj.storage.quality      = zeros(row,1,'uint8');
        end
    end
    
    methods (Access = public)
        acqResult = acq(obj, dataI, dataQ)         %捕获卫星信号
        init(obj, acqResult, n)                    %初始化跟踪参数
        track(obj, dataI, dataQ, deltaFreq)        %跟踪卫星信号
        parse(obj)                                 %解析导航电文
        clean_storage(obj)                         %清理数据存储
        print_log(obj)                             %打印通道日志
        
        % 深组合
        markCurrStorage(obj)                       %标记当前存储行
        [codeDisc, carrDisc] = getDiscOutput(obj)  %获取定位间隔内鉴相器输出
        
        % 通道画图
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