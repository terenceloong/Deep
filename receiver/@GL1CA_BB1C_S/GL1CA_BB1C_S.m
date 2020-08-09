classdef GL1CA_BB1C_S < handle
% GPS L1 C/A & BDS B1C 单天线接收机
% state:接收机状态, 0-初始化, 1-正常, 2-紧组合, 3-深组合
% deepMode:深组合模式, 1-码环矢量跟踪, 2-码环载波环都矢量跟踪

    properties
        Tms            %接收机总运行时间,ms
        sampleFreq     %标称采样频率,Hz
        blockSize      %一个缓存块的采样点数
        blockNum       %缓存块的数量
        buffI          %数据缓存,I路数据
        buffQ          %数据缓存,Q路数据
        buffSize       %数据缓存总采样点数
        blockPtr       %数据该往第几块存,从1开始
        buffHead       %最新数据的位置,blockSize的倍数
        GPSflag        %是否启用GPS
        BDSflag        %是否启用北斗
        GPSweek        %GPS周数
        BDSweek        %北斗周数
        ta             %接收机时间,GPS周内秒数,[s,ms,us]
        dtBDS          %GPS时相对北斗时的时间差,[s,ms,us],tBDS=tGPS-dtBDS
        deltaFreq      %接收机时钟频率误差,无量纲,钟快为正
        tms            %接收机当前运行时间,ms,用采样点数计
        GPS            %GPS模块
        BDS            %BDS模块
        state          %接收机状态
        pos            %接收机位置,纬经高,deg
        rp             %接收机位置,ecef
        vel            %接收机速度,北东地
        vp             %接收机速度,ecef
        att            %姿态,deg
        dtpos          %定位时间间隔,ms
        tp             %下次定位的时间,[s,ms,us]
        ns             %指向当前存储行,初值是0,存储之前加1
        storage        %存储接收机输出
        % 深组合相关变量在深组合初始化时才赋值
        imu            %IMU数据
        navFilter      %导航滤波器
        deepMode       %深组合模式
    end
    
    methods
        function obj = GL1CA_BB1C_S(conf) %构造函数
            %----设置主机参数
            obj.Tms = conf.Tms;
            obj.sampleFreq = conf.sampleFreq;
            obj.blockSize = conf.blockSize;
            obj.blockNum = conf.blockNum;
            obj.buffI = zeros(obj.blockSize, obj.blockNum); %矩阵形式,每一列为一个块
            obj.buffQ = zeros(obj.blockSize, obj.blockNum);
            obj.buffSize = obj.blockSize * obj.blockNum;
            obj.blockPtr = 1;
            obj.buffHead = 0;
            %----设置卫星导航系统
            obj.GPSflag = conf.GPSflag;
            obj.BDSflag = conf.BDSflag;
            %----设置接收机时钟
            obj.GPSweek = conf.GPSweek;
            obj.BDSweek = conf.BDSweek;
            obj.ta = conf.ta;
            obj.dtBDS = [14,0,0]; %GPS时比北斗时快14s
            obj.deltaFreq = 0;
            obj.tms = 0;
            %----设置GPS模块
            if obj.GPSflag==1
                obj.GPS.almanac = conf.GPS.almanac;
                obj.GPS.eleMask = conf.GPS.eleMask;
                obj.GPS.svList = conf.GPS.svList;
                % 使用历书计算所有卫星的方位角高度角
                if ~isempty(obj.GPS.almanac)
                    index = find(obj.GPS.almanac(:,2)==0); %获取健康卫星的行号
                    rs = rs_almanac(obj.GPS.almanac(index,6:end), obj.ta(1)); %卫星ecef位置
                    [azi, ele] = aziele_xyz(rs, conf.p0);
                    obj.GPS.aziele = zeros(length(index),3); %[PRN,azi,ele]
                    obj.GPS.aziele(:,1) = obj.GPS.almanac(index,1);
                    obj.GPS.aziele(:,2) = azi;
                    obj.GPS.aziele(:,3) = ele;
                end
                % 获取跟踪卫星列表
                if isempty(obj.GPS.svList) %如果列表为空,使用历书计算的可见卫星
                    if isempty(obj.GPS.almanac) %如果历书不存在,报错
                        error('GPS almanac doesn''t exist!')
                    end
                    obj.GPS.svList = obj.GPS.aziele(obj.GPS.aziele(:,3)>obj.GPS.eleMask,1)'; %选取高度角大于阈值的卫星
                end
                % 通道配置
                channel_config.sampleFreq = obj.sampleFreq;
                channel_config.buffSize = obj.buffSize;
                channel_config.Tms = obj.Tms;
                channel_config.acqTime = conf.GPS.acqTime;
                channel_config.acqThreshold = conf.GPS.acqThreshold;
                channel_config.acqFreqMax = conf.GPS.acqFreqMax;
                % 创建通道
                obj.GPS.chN = length(obj.GPS.svList);
                obj.GPS.channels = GPS.L1CA.channel(obj.GPS.svList(1), channel_config);
                for k=2:obj.GPS.chN
                    obj.GPS.channels(k) = GPS.L1CA.channel(obj.GPS.svList(k), channel_config);
                end
                obj.GPS.channels = obj.GPS.channels'; %转成列向量
                obj.GPS.iono = NaN(1,8); %GPS电离层参数
            end
            %----设置BDS模块
            if obj.BDSflag==1
                obj.BDS.almanac = conf.BDS.almanac;
                obj.BDS.eleMask = conf.BDS.eleMask;
                obj.BDS.svList = conf.BDS.svList;
                % 使用历书计算所有卫星的方位角高度角
                if ~isempty(obj.BDS.almanac)
                    index = find(obj.BDS.almanac(:,2)==0); %获取健康卫星的行号
                    rs = rs_almanac(obj.BDS.almanac(index,6:end), obj.ta(1)-14); %卫星ecef位置
                    [azi, ele] = aziele_xyz(rs, conf.p0);
                    obj.BDS.aziele = zeros(length(index),3); %[PRN,azi,ele]
                    obj.BDS.aziele(:,1) = obj.BDS.almanac(index,1);
                    obj.BDS.aziele(:,2) = azi;
                    obj.BDS.aziele(:,3) = ele;
                end
                % 获取跟踪卫星列表
                if isempty(obj.BDS.svList) %如果列表为空,使用历书计算的可见卫星
                    if isempty(obj.BDS.almanac) %如果历书不存在,报错
                        error('BDS almanac doesn''t exist!')
                    end
                    obj.BDS.svList = obj.BDS.aziele(obj.BDS.aziele(:,3)>obj.BDS.eleMask,1)'; %选取高度角大于阈值的卫星
                end
                % 通道配置
                channel_config.sampleFreq = obj.sampleFreq;
                channel_config.buffSize = obj.buffSize;
                channel_config.Tms = obj.Tms;
                channel_config.acqThreshold = conf.BDS.acqThreshold;
                channel_config.acqFreqMax = conf.BDS.acqFreqMax;
                % 创建通道
                obj.BDS.chN = length(obj.BDS.svList);
                obj.BDS.channels = BDS.B1C.channel(obj.BDS.svList(1), channel_config);
                for k=2:obj.BDS.chN
                    obj.BDS.channels(k) = BDS.B1C.channel(obj.BDS.svList(k), channel_config);
                end
                obj.BDS.channels = obj.BDS.channels'; %转成列向量
                obj.BDS.iono = NaN(1,9); %BDS电离层参数
            end
            %----设置接收机状态
            obj.state = 0;
            obj.pos = conf.p0;
            obj.rp = lla2ecef(obj.pos);
            obj.vel = [0,0,0];
            obj.vp = [0,0,0];
            obj.att = [0,0,0];
            %----设置定位控制参数
            obj.dtpos = conf.dtpos;
            obj.tp = [obj.ta(1)+2,0,0]; %当前接收机时间的2s后
            %----申请数据存储空间
            obj.ns = 0;
            row = floor(obj.Tms/obj.dtpos); %存储空间行数
            obj.storage.ta        = zeros(row,1,'double');
            obj.storage.df        = zeros(row,1,'single');
            obj.storage.satnav    = zeros(row,8,'double');
            obj.storage.satnavGPS = zeros(row,8,'double');
            obj.storage.satnavBDS = zeros(row,8,'double');
            obj.storage.pos       = zeros(row,3,'double');
            obj.storage.vel       = zeros(row,3,'single');
            obj.storage.att     =   NaN(row,3,'single');
            obj.storage.imu     =   NaN(row,6,'single');
            obj.storage.bias    =   NaN(row,6,'single');
            obj.storage.P       =   NaN(row,17,'single');
        end
    end
    
    methods (Access = public)
        run(obj, data)                %运行函数
        clean_storage(obj)            %清理数据存储
        set_ephemeris(obj, filename)  %预设星历
        save_ephemeris(obj, filename) %保存星历
        print_all_log(obj)            %打印所有通道日志
        plot_all_trackResult(obj)     %显示所有通道跟踪结果
        interact_constellation(obj)   %画交互星座图
%         get_result(obj)               %获取接收机运行结果
        imu_input(obj, tp, imu)       %IMU数据输入
        channel_deep(obj)             %通道切换深组合跟踪环路
        
%         plot_sv_3d(obj)
        plot_df(obj)
        plot_pos(obj)
        plot_vel(obj)
        plot_att(obj)
        plot_bias_gyro(obj)
        plot_bias_acc(obj)
        kml_output(obj)
    end
    
    methods (Access = private)
        acqProcessGPS(obj)             %GPS捕获过程
        trackProcessGPS(obj)           %GPS跟踪过程
        acqProcessBDS(obj)             %BDS捕获过程
        trackProcessBDS(obj)           %BDS跟踪过程
        satmeas = get_satmeas_GPS(obj) %获取GPS卫星测量
        satmeas = get_satmeas_BDS(obj) %获取BDS卫星测量
        pos_init(obj)                  %初始化定位
        pos_normal(obj)                %正常定位
%         pos_tight(obj)                 %紧组合定位
        pos_deep(obj)                  %深组合定位
    end
    
end %end classdef