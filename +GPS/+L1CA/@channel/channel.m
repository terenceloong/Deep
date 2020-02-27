classdef channel < handle
% GPS L1 C/A信号跟踪通道
    
    properties (GetAccess = public, SetAccess = private)
        sampleFreq      %标称采样频率,Hz
        buffSize        %数据缓存总采样点数
        PRN             %卫星编号
        CAcode          %一个周期的C/A码
        state           %通道状态,0:未激活,1;已激活但没有星历,2:可以进行伪距伪距率测量
        acqN            %捕获采样点数
        acqThreshold    %捕获阈值,最高峰与第二大峰的比值
        acqFreq         %搜索频率范围
        acqM            %搜索频率个数
        CODE            %C/A码的FFT
        code            %本地码发生器用的C/A码
        timeIntMs       %积分时间,ms (1,2,4,5,10,20)
        timeIntS        %积分时间,s
        codeInt         %积分时间内码片个数
        pointInt        %一个比特有多少个积分点,一个比特20ms
        trackDataTail   %跟踪开始点在数据缓存中的位置
        trackBlockSize  %跟踪数据段采样点个数
        trackDataHead   %跟踪结束点在数据缓存中的位置
        dataIndex       %跟踪开始点在文件中的位置
        carrAcc         %载波频率变化率
        carrNco         %载波发生器驱动频率
        codeNco         %码发生器驱动频率
        remCarrPhase    %跟踪开始点的载波相位
        remCodePhase    %跟踪开始点的码相位
        carrFreq        %测量的载波频率
        codeFreq        %测量的码频率
        I               %I路积分值
        Q               %Q路积分值
        FLLp            %频率牵引锁频环
        PLL2             %二阶锁相环
        DLL2            %二阶延迟锁定环
        carrMode        %载波跟踪模式
        codeMode        %码跟踪模式
        tc0             %下一伪码周期的开始时间,ms
        msgStage        %电文解析阶段(字符)
        msgCnt          %电文解析计数器
        I0              %上次I路积分值(用于比特同步)
        bitSyncTable    %比特同步统计表
        bitBuff         %比特缓存
        frameBuff       %帧缓存
        frameBuffPoint  %帧缓存指针
        iono            %电离层校正参数
        log             %日志
        ns              %指向当前存储行,初值是0,刚开始运行track时加1
        storage         %存储跟踪结果
    end
    
    % 星历可以在外部赋值
    properties (GetAccess = public, SetAccess = public)
        ephe            %星历
    end
    
    methods
        %% 构造函数
        function obj = channel(PRN, conf)
            % PRN:卫星编号
            % conf:通道配置结构体
            %----设置不会变的参数
            obj.sampleFreq = conf.sampleFreq;
            obj.buffSize = conf.buffSize;
            obj.PRN = PRN;
            obj.CAcode = GPS.L1CA.codeGene(PRN);
            %----设置通道状态
            obj.state = 0;
            %----设置捕获参数
            obj.acqN = obj.sampleFreq*0.001 * conf.acqTime;
            obj.acqThreshold = conf.acqThreshold;
            obj.acqFreq = -conf.acqFreqMax:(obj.sampleFreq/obj.acqN/2):conf.acqFreqMax;
            obj.acqM = length(obj.acqFreq);
            index = mod(floor((0:obj.acqN-1)*1.023e6/obj.sampleFreq),1023) + 1; %C/A码采样的索引
            obj.CODE = fft(obj.CAcode(index));
            %---申请星历空间
            obj.ephe = NaN(1,25);
            obj.iono = NaN(1,8);
            %----申请数据存储空间
            obj.ns = 0;
            row = conf.Tms; %存储空间行数
            obj.storage.dataIndex    =   NaN(row,1,'double'); %使用预设NaN存数据,方便通道断开时数据显示有中断
            obj.storage.remCodePhase =   NaN(row,1,'single');
            obj.storage.codeFreq     =   NaN(row,1,'double');
            obj.storage.remCarrPhase =   NaN(row,1,'single');
            obj.storage.carrFreq     =   NaN(row,1,'double');
            obj.storage.carrAcc      =   NaN(row,1,'single');
            obj.storage.I_Q          = zeros(row,6,'int32');
            obj.storage.disc         =   NaN(row,3,'single');
            obj.storage.bitFlag      = zeros(row,1,'uint8'); %导航电文比特开始标志
        end
        
        %% 清理数据储存
        function clean_storage(obj)
            n = obj.ns + 1;
            obj.storage.dataIndex(n:end)    = [];
            obj.storage.remCodePhase(n:end) = [];
            obj.storage.codeFreq(n:end)     = [];
            obj.storage.remCarrPhase(n:end) = [];
            obj.storage.carrFreq(n:end)     = [];
            obj.storage.carrAcc(n:end)      = [];
            obj.storage.I_Q(n:end,:)        = [];
            obj.storage.disc(n:end,:)       = [];
            obj.storage.bitFlag(n:end)      = [];
        end
        
        %% 设置载波频率变化率
        function set_carrAcc(obj, x)
            obj.carrAcc = x;
        end
        
    end %end methods
    
end %end classdef