classdef GL1CA_S < handle
% GPS L1 C/A单天线接收机
% state:接收机状态, 0-初始化, 1-正常, 2-紧组合, 3-深组合, 4-纯矢量跟踪
    
    properties
        Tms            %接收机总运行时间,ms
        sampleFreq     %标称采样频率,Hz
        blockSize      %一个缓存块的采样点数
        blockTime      %一个缓存块对应的接收机时间
        blockNum       %缓存块的数量
        buffI          %数据缓存,I路数据
        buffQ          %数据缓存,Q路数据
        buffSize       %数据缓存总采样点数
        blockPtr       %数据该往第几块存,从1开始
        buffHead       %最新数据的位置,blockSize的倍数
        week           %GPS周数
        ta             %接收机时间,GPS周内秒数,[s,ms,us]
        clockError     %累计钟差修正量(如果不修接收机时钟会产生多少钟差)
        deltaFreq      %接收机时钟频率误差,无量纲,钟快为正
        tms            %接收机当前运行时间,ms,用采样点数计
        CN0Thr         %载噪比阈值
        almanac        %所有卫星的历书
        aziele         %使用历书计算的卫星方位角高度角
        eleMask        %高度角阈值
        svList         %跟踪卫星列表
        chN            %跟踪通道数量
        channels       %跟踪通道
        state          %接收机状态
        pos            %接收机位置,纬经高,deg
        rp             %接收机位置,ecef
        vel            %接收机速度,北东地
        vp             %接收机速度,ecef
        att            %姿态,deg
        fn0            %上次地理系下的加速度
        geogInfo       %地理信息
        iono           %电离层校正参数
        dtpos          %定位时间间隔,ms
        tp             %下次定位的时间,[s,ms,us]
        imu            %IMU数据
        navFilter      %导航滤波器
        vectorMode     %矢量跟踪模式
        ns             %指向当前存储行,初值是0,存储之前加1
        storage        %存储接收机输出
        result         %接收机运行结果
    end
    
    methods
        function obj = GL1CA_S(conf) %构造函数
            % conf:接收机配置结构体
            %----设置主机参数
            obj.Tms = conf.Tms;
            obj.sampleFreq = conf.sampleFreq;
            obj.blockSize = conf.blockSize;
            obj.blockTime = obj.blockSize / obj.sampleFreq;
            obj.blockNum = conf.blockNum;
            obj.buffI = zeros(obj.blockSize, obj.blockNum); %矩阵形式,每一列为一个块
            obj.buffQ = zeros(obj.blockSize, obj.blockNum);
            obj.buffSize = obj.blockSize * obj.blockNum;
            obj.blockPtr = 1;
            obj.buffHead = 0;
            %----设置接收机时钟
            obj.week = conf.week;
            obj.ta = conf.ta;
            obj.clockError = 0;
            obj.deltaFreq = 0;
            obj.tms = 0;
            %----设置载噪比阈值
            obj.CN0Thr = CNR_threshold(conf.CN0Thr);
            %----设置历书
            obj.almanac = conf.almanac;
            %----使用历书计算所有卫星方位角高度角
            if ~isempty(obj.almanac) %如果没有历书,aziele为空
                index = find(obj.almanac(:,2)==0); %获取健康卫星的行号
                rs = rs_almanac(obj.almanac(index,5:end), [obj.week,obj.ta(1)]); %卫星ecef位置
                [azi, ele] = aziele_xyz(rs, conf.p0);
                obj.aziele = zeros(length(index),3); %[PRN,azi,ele]
                obj.aziele(:,1) = obj.almanac(index,1);
                obj.aziele(:,2) = azi;
                obj.aziele(:,3) = ele;
            end
            %----获取跟踪卫星列表
            obj.eleMask = conf.eleMask;
            obj.svList = conf.svList;
            if isempty(obj.svList) %如果列表为空,使用历书计算的可见卫星
                if isempty(obj.almanac) %如果历书不存在,报错
                    error('Almanac doesn''t exist!')
                end
                obj.svList = obj.aziele(obj.aziele(:,3)>obj.eleMask,1)'; %选取高度角大于阈值的卫星
            end
            %----通道配置
            channel_config.sampleFreq = obj.sampleFreq;
            channel_config.buffSize = obj.buffSize;
            channel_config.Tms = obj.Tms;
            channel_config.acqTime = conf.acqTime;
            channel_config.acqThreshold = conf.acqThreshold;
            channel_config.acqFreqMax = conf.acqFreqMax;
            channel_config.CN0Thr = obj.CN0Thr;
            %----创建通道
            obj.chN = length(obj.svList);
            obj.channels = GPS.L1CA.channel.empty; %创建类的空矩阵
            for k=1:obj.chN
                obj.channels(k) = GPS.L1CA.channel(obj.svList(k), channel_config);
            end
            obj.channels = obj.channels'; %转成列向量
            %----设置接收机状态
            obj.state = 0;
            obj.pos = conf.p0;
            obj.rp = lla2ecef(obj.pos);
            obj.vel = [0,0,0];
            obj.vp = [0,0,0];
            obj.att = [0,0,0];
            obj.fn0 = NaN(1,3);
            obj.geogInfo = geogInfo_cal(obj.pos, obj.vel);
            obj.iono = NaN(1,8);
            %----设置定位控制参数
            obj.dtpos = conf.dtpos;
            obj.tp = [obj.ta(1)+2,0,0]; %当前接收机时间的2s后
            %----申请数据存储空间
            obj.ns = 0;
            row = floor(obj.Tms/obj.dtpos); %存储空间行数
            obj.storage.ta      = zeros(row,1,'double');
            obj.storage.df      = zeros(row,1,'single');
            obj.storage.satmeas = zeros(obj.chN,12,row,'double');
            obj.storage.satnav  = zeros(row,8,'double');
            obj.storage.svsel   = zeros(row,obj.chN,'uint8');
            obj.storage.pos     = zeros(row,3,'double');
            obj.storage.vel     = zeros(row,3,'single');
            obj.storage.att     =   NaN(row,3,'single');
            obj.storage.imu     =   NaN(row,6,'single');
            obj.storage.bias    =   NaN(row,6,'single');
            obj.storage.P       =   NaN(row,20,'single');
            obj.storage.motion  = zeros(row,1,'uint8'); %运动状态
            obj.storage.others  =   NaN(row,12,'single');
            obj.storage.innP    =   NaN(row,obj.chN,'single'); %新息(innovation)
            obj.storage.innV    =   NaN(row,obj.chN,'single');
            obj.storage.resP    =   NaN(row,obj.chN,'single'); %残差(residual)
            obj.storage.resV    =   NaN(row,obj.chN,'single');
        end
    end
    
    methods (Access = public)
        run(obj, data)                %运行函数
        clean_storage(obj)            %清理数据存储
        set_ephemeris(obj, filename)  %预设星历
        save_ephemeris(obj, filename) %保存星历
        interact_constellation(obj)   %画交互星座图
        get_result(obj)               %获取接收机运行结果
        imu_input(obj, tp, imu)       %IMU数据输入
        channel_vector(obj)           %通道切换矢量跟踪环路
        
        print_all_log(obj)            %打印所有通道日志
        plot_all_trackResult(obj)     %显示所有通道跟踪结果
        plot_all_I_Q(obj)
        plot_all_I_P(obj)
        plot_all_CN0(obj)
        plot_all_carrNco(obj)
        plot_all_carrAcc(obj)
        plot_all_drho(obj)
        
        plot_sv_3d(obj)
        plot_svnum(obj)
        plot_visibility(obj)
        plot_motionState(obj)
        [azi, ele] = cal_aziele(obj)
        cal_iono(obj)
        plot_df(obj)
        plot_pos(obj)
        plot_vel(obj)
        plot_att(obj)
        plot_bias_gyro(obj)
        plot_bias_acc(obj)
        kml_output(obj)
    end
    
    methods (Access = private)
        acqProcess(obj)            %捕获过程
        trackProcess(obj)          %跟踪过程
        satmeas = get_satmeas(obj) %获取卫星测量
        pos_init(obj)              %初始化定位
        pos_normal(obj)            %正常定位
        pos_tight(obj)             %紧组合定位
        pos_deep(obj)              %深组合定位
        pos_vector(obj)            %纯矢量跟踪定位
    end
    
end %end classdef