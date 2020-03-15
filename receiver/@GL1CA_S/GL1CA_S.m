classdef GL1CA_S < handle
% GPS L1 C/A单天线接收机
    
    properties (GetAccess = public, SetAccess = private)
        Tms            %接收机总运行时间,ms
        sampleFreq     %标称采样频率,Hz
        blockSize      %一个缓存块的采样点数
        blockNum       %缓存块的数量
        buffI          %数据缓存,I路数据
        buffQ          %数据缓存,Q路数据
        buffSize       %数据缓存总采样点数
        blockPoint     %数据该往第几块存,从1开始
        buffHead       %最新数据的位置,blockSize的倍数
        week           %GPS周数
        ta             %接收机时间,GPS周内秒数,[s,ms,us]
        deltaFreq      %接收机时钟频率误差,无量纲,钟快为正
        tms            %接收机当前运行时间,ms,用采样点数计
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
        iono           %电离层校正参数
        dtpos          %定位时间间隔,ms
        tp             %下次定位的时间,[s,ms,us]
        imu            %IMU数据
        ns             %指向当前存储行,初值是0,存储之前加1
        storage        %存储接收机输出
        result         %接收机运行结果
    end
    
    methods
        %% 构造函数
        function obj = GL1CA_S(conf)
            % conf:接收机配置结构体
            %----设置主机参数
            obj.Tms = conf.Tms;
            obj.sampleFreq = conf.sampleFreq;
            obj.blockSize = conf.blockSize;
            obj.blockNum = conf.blockNum;
            obj.buffI = zeros(obj.blockSize, obj.blockNum); %矩阵形式,每一列为一个块
            obj.buffQ = zeros(obj.blockSize, obj.blockNum);
            obj.buffSize = obj.blockSize * obj.blockNum;
            obj.blockPoint = 1;
            obj.buffHead = 0;
            %----设置接收机时钟
            obj.week = conf.week;
            obj.ta = conf.ta;
            obj.deltaFreq = 0;
            obj.tms = 0;
            %----设置历书
            obj.almanac = conf.almanac;
            %----使用历书计算所有卫星方位角高度角
            if ~isempty(obj.almanac) %如果没有历书,aziele为空
                index = find(obj.almanac(:,2)==0); %获取健康卫星的行号
                rs = rs_almanac(obj.almanac(index,6:end), obj.ta(1)); %卫星ecef位置
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
            %----创建通道
            obj.chN = length(obj.svList);
            obj.channels = GPS.L1CA.channel(obj.svList(1), channel_config);
            % 先创建一个对象用来确定channel的数据类型,后面才能用索引往下续
            for k=2:obj.chN
                obj.channels(k) = GPS.L1CA.channel(obj.svList(k), channel_config);
            end
            obj.channels = obj.channels'; %转成列向量
            %----设置接收机状态
            obj.state = 0;
            obj.pos = conf.p0;
            obj.rp = lla2ecef(obj.pos);
            obj.vel = [0,0,0];
            obj.vp = [0,0,0];
            obj.iono = NaN(1,8);
            %----设置定位控制参数
            obj.dtpos = conf.dtpos;
            obj.tp = obj.ta + [2,0,0]; %当前接收机时间的2s后
            %----申请数据存储空间
            obj.ns = 0;
            row = floor(obj.Tms/obj.dtpos); %存储空间行数
            obj.storage.ta      = zeros(row,1,'double');
            obj.storage.state   = zeros(row,1,'uint8');
            obj.storage.df      = zeros(row,1,'single');
            obj.storage.satmeas = zeros(obj.chN,8,row,'double');
            obj.storage.satnav  = zeros(row,8,'double');
            obj.storage.pos     = zeros(row,3,'double');
            obj.storage.vel     = zeros(row,3,'single');
        end
        
        %% 清理数据存储
        function clean_storage(obj)
            % 清理通道内多余的存储空间
            for k=1:obj.chN
                obj.channels(k).clean_storage;
            end
            % 获取所有场名,元胞数组
            fields = fieldnames(obj.storage);
            % 清理多余的接收机输出存储空间
            n = obj.ns + 1;
            for k=1:length(fields)
                if size(obj.storage.(fields{k}),3)==1 %二维存储空间
                    obj.storage.(fields{k})(n:end,:) = [];
                else %三维存储空间
                    obj.storage.(fields{k})(:,:,n:end) = [];
                end
            end
            % 整理卫星测量信息,元胞数组,每个通道一个矩阵
            n = size(obj.storage.satmeas,3); %存储元素个数
            if n>0
                satmeas = cell(obj.chN,1);
                for k=1:obj.chN
                    satmeas{k} = reshape(obj.storage.satmeas(k,:,:),8,n)';
                end
                obj.storage.satmeas = satmeas;
            end
        end
        
        %% 预设星历
        function set_ephemeris(obj, filename)
            if ~exist(filename, 'file') %如果文件不存在就创建一个
                ephemeris = []; %变量名为ephemeris,是个结构体
                save(filename, 'ephemeris')
            end
            load(filename, 'ephemeris') %加载预存的星历
            if ~isfield(ephemeris, 'GPS_ephe') %如果星历中不存在GPS星历,创建空GPS星历
                ephemeris.GPS_ephe = NaN(32,25);
                ephemeris.GPS_iono = NaN(1,8);
                save(filename, 'ephemeris') %保存到文件中
            end
            obj.iono = ephemeris.GPS_iono; %提取电离层校正参数
            for k=1:obj.chN %为每个通道赋星历
                obj.channels(k).set_ephe(ephemeris.GPS_ephe(obj.channels(k).PRN,:));
            end
        end
        
        %% 保存星历
        function save_ephemeris(obj, filename)
            load(filename, 'ephemeris') %加载预存的星历
            ephemeris.GPS_iono = obj.iono; %保存电离层校正参数
            for k=1:obj.chN %提取有星历通道的星历
                if ~isnan(obj.channels(k).ephe(1))
                    ephemeris.GPS_ephe(obj.channels(k).PRN,:) = obj.channels(k).ephe;
                end
            end
            save(filename, 'ephemeris') %保存到文件中
        end
        
        %% 打印所有通道日志
        function print_all_log(obj)
            disp('<----------------------------------------------------->')
            for k=1:obj.chN
                obj.channels(k).print_log;
            end
        end
        
        %% 显示所有通道跟踪结果
        function plot_all_trackResult(obj)
            for k=1:obj.chN
                if obj.channels(k).ns>0 %只画有跟踪数据的通道
                    plot_trackResult(obj.channels(k));
                end
            end
        end
        
        %% IMU数据输入
        function imu_input(obj, tp, imu)
            % tp:下次的定位时间,s
            % imu:下次的IMU数据
            obj.tp = sec2smu(tp); %[s,ms,us]
            obj.imu = imu;
        end
        
        %% 进入深组合模式
        function enter_deep(obj)
            obj.state = 2;
        end
        
    end %end methods
    
end %end classdef