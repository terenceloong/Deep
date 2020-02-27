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
        iono           %电离层校正参数
        dtpos          %定位时间间隔,ms
        tp             %下次定位的时间,[s,ms,us]
        ns             %指向当前存储行,初值是0,存储之前加1
        storage        %存储接收机输出
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
                obj.aziele = zeros(length(index),3); %[ID,azi,ele]
                obj.aziele(:,1) = obj.almanac(index,1);
                obj.aziele(:,2:3) = aziele_almanac(obj.almanac(index,6:end), obj.ta(1), conf.p0);
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
            obj.iono = NaN(1,8);
            %----设置定位控制参数
            obj.dtpos = conf.dtpos;
            obj.tp = obj.ta + [2,0,0]; %当前接收机时间的2s后
            %----申请数据存储空间
            obj.ns = 0;
            row = floor(obj.Tms/obj.dtpos); %存储空间行数
            obj.storage.ta     = zeros(row,1,'double');
            obj.storage.state  = zeros(row,1,'uint8');
            obj.storage.satnav = zeros(row,11,'double');
            obj.storage.sat    = zeros(obj.chN,8,row,'double');
            obj.storage.df     = zeros(row,1,'double');
        end
        
        %% 运行函数
        function run(obj, data)
            % data:采样数据,两行,分别为I/Q数据,原始数据类型
            % 使用嵌套函数写,提高程序可读性,要保证只有obj是全局变量
            %----往数据缓存存数
            obj.buffI(:,obj.blockPoint) = data(1,:); %往数据缓存的指定块存数,不用加转置,自动变成列向量
            obj.buffQ(:,obj.blockPoint) = data(2,:);
            obj.buffHead = obj.blockPoint * obj.blockSize; %最新数据的位置
            obj.blockPoint = obj.blockPoint + 1; %指向下一块
            if obj.blockPoint>obj.blockNum
                obj.blockPoint = 1;
            end
            obj.tms = obj.tms + 1; %当前运行时间加1ms
            %----更新接收机时间
            fs = obj.sampleFreq * (1+obj.deltaFreq); %修正后的采样频率
            obj.ta = timeCarry(obj.ta + sample2dt(obj.blockSize, fs));
            %----捕获
            if mod(obj.tms,1000)==0 %1s搜索一次
                acqProcess;
            end
            %----跟踪
            trackProcess;
            %----定位
            dtp = (obj.ta-obj.tp) * [1;1e-3;1e-6]; %当前接收机时间与定位时间之差,s
            if dtp>=0 %定位时间到了
                % 获取卫星测量信息
                sat = getSat(dtp, fs);
                % 位置速度解算
                sv = sat(~isnan(sat(:,1)),:); %选有数据的行
                satnav = satnavSolve(sv, obj.rp);
                if ~isnan(satnav(1))
                    obj.pos = satnav(1:3);
                    obj.rp = satnav(4:6);
                    obj.vel = satnav(7:9);
                end
                % 接收机时钟修正
                
                % 数据存储
                obj.ns = obj.ns+1; %指向当前存储行
                m = obj.ns;
                obj.storage.ta(m) = obj.tp * [1;1e-3;1e-6]; %定位时间,s
                obj.storage.state(m) = obj.state;
                obj.storage.satnav(m,:) = satnav;
                obj.storage.sat(:,:,m) = sat;
                obj.storage.df(m) = obj.deltaFreq;
                % 接收机时钟初始化
                if obj.state==0
                    clockInit(satnav(10));
                end
                % 更新下次定位时间
                obj.tp = timeCarry(obj.tp + [0,obj.dtpos,0]);
            end
            
            %% 捕获过程
            function acqProcess
                for k=1:obj.chN
                    if obj.channels(k).state~=0 %如果通道已激活,跳过捕获
                        continue
                    end
                    n = obj.channels(k).acqN; %捕获采样点数
                    acqResult = obj.channels(k).acq(obj.buffI((end-2*n+1):end), obj.buffQ((end-2*n+1):end));
                    if ~isempty(acqResult) %捕获成功后初始化通道
                        obj.channels(k).init(acqResult, obj.tms/1000*obj.sampleFreq);
                    end
                end
            end
            
            %% 跟踪过程
            function trackProcess
                for k=1:obj.chN
                    if obj.channels(k).state==0 %如果通道未激活,跳过跟踪
                        continue
                    end
                    while 1
                        %----判断是否有完整的跟踪数据
                        if mod(obj.buffHead-obj.channels(k).trackDataHead,obj.buffSize)>(obj.buffSize/2)
                            break
                        end
                        %----信号处理
                        n1 = obj.channels(k).trackDataTail;
                        n2 = obj.channels(k).trackDataHead;
                        if n2>n1
                            obj.channels(k).track(obj.buffI(n1:n2), obj.buffQ(n1:n2), obj.deltaFreq);
                        else
                            obj.channels(k).track([obj.buffI(n1:end),obj.buffI(1:n2)], ...
                                                  [obj.buffQ(n1:end),obj.buffQ(1:n2)], obj.deltaFreq);
                        end
                        %----解析导航电文
                        ionoflag = obj.channels(k).parse;
                        %----提取电离层校正参数
                        if ionoflag==1
                            obj.iono = obj.channels(k).iono;
                        end
                    end
                end
            end
            
            %% 获取卫星测量
            function sat = getSat(dtp, fs)
                % dtp:当前采样点到定位点的时间差,s,dtp=ta-tp
                % fs:接收机钟频差校正后的采样频率,Hz
                % sat:[x,y,z,vx,vy,vz,rho,rhodot]
                lamda = 0.190293672798365; %载波波长,m,299792458/1575.42e6
                sat = NaN(obj.chN,8);
                for k=1:obj.chN
                    if obj.channels(k).state==2 %只要跟踪上的通道都能测,这里不用管信号质量,选星额外来做
                        %----计算定位点所接到码的发射时间
                        dn = mod(obj.buffHead-obj.channels(k).trackDataTail+1, obj.buffSize) - 1; %恰好超前一个采样点时dn=-1
                        dtc = dn / fs; %当前采样点到跟踪点的时间差,dtc=ta-tc
                        dt = dtc - dtp; %定位点到跟踪点的时间差,dtc-dtp=(ta-tc)-(ta-tp)=tp-tc=dt
                        codePhase = obj.channels(k).remCodePhase + obj.channels(k).codeNco*dt; %定位点码相位
                        te = [floor(obj.channels(k).tc0/1e3), mod(obj.channels(k).tc0,1e3), 0] + ...
                              [0, floor(codePhase/1023), mod(codePhase/1023,1)*1e3]; %定位点码发射时间
                        %----计算信号发射时刻卫星位置速度
                        % [sat(k,1:6), corr] =LNAV.rsvs_emit(obj.channels(k).ephe(5:end), te, obj.rp, obj.iono, obj.pos);
                        %----计算信号发射时刻卫星位置速度加速度
                        [rsvsas, corr] =LNAV.rsvsas_emit(obj.channels(k).ephe(5:end), te, obj.rp, obj.iono, obj.pos);
                        sat(k,1:6) = rsvsas(1:6);
                        %----计算卫星运动引起的载波频率变化率(短时间近似不变,使用上一时刻的位置计算就行,视线矢量差别不大)
                        rs = rsvsas(1:3); %卫星位置矢量
                        vs = rsvsas(4:6); %卫星速度矢量
                        as = rsvsas(7:9); %卫星加速度矢量
                        rps = rs - obj.rp; %接收机指向卫星位置矢量
                        R = norm(rps); %接收机到卫星的距离
                        carrAcc = -(as*rps'+vs*vs'-(vs*rps'/R)^2)/R / lamda; %载波频率变化率,Hz/s
                        obj.channels(k).set_carrAcc(carrAcc); %设置跟踪通道载波频率变化率
                        %----计算伪距伪距率
                        tt = (obj.tp-te) * [1;1e-3;1e-6]; %信号传播时间,s
                        doppler = obj.channels(k).carrFreq/1575.42e6 + obj.deltaFreq; %归一化,接收机钟快使多普勒变小(发生在下变频)
                        sat(k,7:8) = satmeasCorr(tt, doppler, corr);
                    end
                end
            end
            
            %% 接收机时钟初始化
            function clockInit(dtr)
                % dtr:卫星导航解算得到的钟差,s
                if isnan(dtr) %没有钟差直接退出
                    return
                end
                if abs(dtr)>0.1e-3 %钟差大于0.1ms,修正接收机时间
                    obj.ta = obj.ta - sec2smu(dtr);
                    obj.ta = timeCarry(obj.ta);
                    obj.tp(1) = obj.ta(1); %更新下次定位时间
                    obj.tp(2) = ceil(obj.ta(2)/obj.dtpos) * obj.dtpos;
                    obj.tp = timeCarry(obj.tp);
                else %钟差小于0.1ms，初始化结束
                    obj.state = 1;
                end
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
                obj.channels(k).ephe = ephemeris.GPS_ephe(obj.channels(k).PRN,:);
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
        
        %% 清理数据储存
        function clean_storage(obj)
            % 清理通道内多余的存储空间
            for k=1:obj.chN
                obj.channels(k).clean_storage;
            end
            % 清理多余的接收机输出存储空间
            n = obj.ns + 1;
            obj.storage.ta(n:end)       = [];
            obj.storage.state(n:end)    = [];
            obj.storage.satnav(n:end,:) = [];
            obj.storage.sat(:,:,n:end)  = [];
            obj.storage.df(n:end)       = [];
            % 删除接收机未初始化时的数据
            index = find(obj.storage.state==0);
            obj.storage.ta(index)       = [];
            obj.storage.state(index)    = [];
            obj.storage.satnav(index,:) = [];
            obj.storage.sat(:,:,index)  = [];
            obj.storage.df(index)       = [];
            % 整理卫星测量信息,元胞数组,每个通道一个矩阵
            n = size(obj.storage.sat,3); %存储元素个数
            if n>0
                sat = cell(obj.chN,1);
                for k=1:obj.chN
                    sat{k} = reshape(obj.storage.sat(k,:,:),8,n)';
                end
                obj.storage.sat = sat;
            end
        end
        
        %% 打印通道日志
        function print_log(obj)
            for k=1:obj.chN
                fprintf('PRN %d\n', obj.channels(k).PRN); %使用\r\n会多一个空行
                n = length(obj.channels(k).log); %通道日志的行数
                if n>0 %如果日志有内容,逐行打印
                    for m=1:n
                        disp(obj.channels(k).log(m));
                    end
                end
                disp(' ');
            end
        end
        
        %% 显示跟踪结果
        function show_trackResult(obj)
            for k=1:obj.chN %处理所有通道
                if obj.channels(k).ns==0 %不画没跟踪的通道
                    continue
                end
                figure('Position', screenBlock(1140,670,0.5,0.5)); %新建画图窗口
                ax1 = axes('Position', [0.08, 0.4, 0.38, 0.53]);
                hold(ax1,'on');
                axis(ax1, 'equal');
                title(['PRN = ',sprintf('%d',obj.channels(k).PRN)])
                ax2 = axes('Position', [0.53, 0.7 , 0.42, 0.25]);
                hold(ax2,'on');
                ax3 = axes('Position', [0.53, 0.38, 0.42, 0.25]);
                hold(ax3,'on');
                grid(ax3,'on');
                ax4 = axes('Position', [0.53, 0.06, 0.42, 0.25]);
                hold(ax4,'on');
                grid(ax4,'on');
                ax5 = axes('Position', [0.05, 0.06, 0.42, 0.25]);
                hold(ax5,'on');
                grid(ax5,'on');
                t = obj.channels(k).storage.dataIndex/obj.sampleFreq; %使用采样点计算的时间
                % I/Q图
                plot(ax1, obj.channels(k).storage.I_Q(1001:end,1),obj.channels(k).storage.I_Q(1001:end,4), ...
                          'LineStyle','none', 'Marker','.')
                % I_P图
                plot(ax2, t, double(obj.channels(k).storage.I_Q(:,1))) %横纵坐标数据类型要一样
                set(ax2, 'XLim',[1,obj.Tms/1000])
                % 载波频率
                plot(ax4, t, obj.channels(k).storage.carrFreq, 'LineWidth',1.5)
                set(ax4, 'XLim',[1,obj.Tms/1000])
                % 载波频率变化率
                plot(ax5, t, obj.channels(k).storage.carrAcc, 'LineWidth',1.5)
                set(ax5, 'XLim',[1,obj.Tms/1000])
            end
        end
        
        %% 显示星座图
        function plot_constellation(obj)
            if isempty(obj.almanac) %如果没有历书不画图
                disp('Almanac doesn''t exist!')
                return
            end
            %----挑选高度角大于0的卫星
            index = find(obj.aziele(:,3)>0); %高度角大于0的卫星索引
            PRN = obj.aziele(index,1);
            azi = mod(obj.aziele(index,2),360)/180*pi; %方位角转成弧度,0~360度
            ele = obj.aziele(index,3); %高度角,deg
            %----统计跟踪到的卫星
            svTrack = obj.svList([obj.channels.ns]~=0);
            %----画图
            figure
            ax = polaraxes; %创建极坐标轴
            ax.NextPlot = 'add';
            ax.RLim = [0,90]; %高度角范围
            ax.RDir = 'reverse'; %高度角里面是90度
            ax.RTick = [0,15,30,45,60,75,90]; %高度角刻度
            ax.ThetaDir = 'clockwise'; %顺时针方位角增加
            ax.ThetaZeroLocation = 'top'; %方位角0在上
            for k=1:length(PRN) %处理所有高度角大于0的卫星
                % 低高度角卫星,透明
                if ele(k)<obj.eleMask
                    polarscatter(azi(k),ele(k), 220, 'MarkerFaceColor',[65,180,250]/255, ...
                                 'MarkerEdgeColor',[127,127,127]/255, 'MarkerFaceAlpha',0.5)
                    text(azi(k),ele(k),num2str(PRN(k)), 'HorizontalAlignment','center', ...
                                                        'VerticalAlignment','middle');
                    continue
                end
                % 没跟踪的卫星,边框正常
                if ~ismember(PRN(k),svTrack)
                    polarscatter(azi(k),ele(k), 220, 'MarkerFaceColor',[65,180,250]/255, ...
                                 'MarkerEdgeColor',[127,127,127]/255)
                    text(azi(k),ele(k),num2str(PRN(k)), 'HorizontalAlignment','center', ...
                                                        'VerticalAlignment','middle');
                    continue
                end
                % 跟踪到的卫星,边框加粗,设置右键菜单,参见uicontextmenu help
                polarscatter(azi(k),ele(k), 220, 'MarkerFaceColor',[65,180,250]/255, ...
                             'MarkerEdgeColor',[127,127,127]/255, 'LineWidth',2)
                t = text(azi(k),ele(k),num2str(PRN(k)), 'HorizontalAlignment','center', ...
                                                        'VerticalAlignment','middle');
                c = uicontextmenu; %创建目录
                t.UIContextMenu = c; %目录加到text上,因为文字覆盖了圆圈
                ch = find(obj.svList==PRN(k)); %该颗卫星的通道号
                uimenu(c, 'MenuSelectedFcn',@customplot, 'UserData',ch, 'Text','I_Q'); %创建目录项
                uimenu(c, 'MenuSelectedFcn',@customplot, 'UserData',ch, 'Text','I_P');
                uimenu(c, 'MenuSelectedFcn',@customplot, 'UserData',ch, 'Text','I_P(flag)');
                uimenu(c, 'MenuSelectedFcn',@customplot, 'UserData',ch, 'Text','carrFreq');
                uimenu(c, 'MenuSelectedFcn',@customplot, 'UserData',ch, 'Text','codeFreq');
            end
            %----回调函数
            function customplot(source, ~)
                % 必须要有两个输入参数(source, callbackdata),名字不重要
                % 第一个返回matlab.ui.container.Menu对象
                % 第二个返回ui.eventdata.ActionData
                % source.UserData为通道号
                switch source.Text
                    case 'I_Q'
                        plot_I_Q(obj, source.UserData)
                    case 'I_P'
                        plot_I_P(obj, source.UserData)
                    case 'I_P(flag)' %在I_P图上标记比特开始标志
                        plot_I_P_flag(obj, source.UserData)
                    case 'carrFreq'
                        plot_carrFreq(obj, source.UserData)
                    case 'codeFreq'
                        plot_codeFreq(obj, source.UserData)
                end
            end
        end
        
    end %end methods
    
end %end classdef

%% 交互画图函数
function plot_I_Q(obj, k)
    figure
    plot(obj.channels(k).storage.I_Q(1001:end,1),obj.channels(k).storage.I_Q(1001:end,4), ...
         'LineStyle','none', 'Marker','.')
    axis equal
end

function plot_I_P(obj, k)
    figure('Position', screenBlock(1000,300,0.5,0.5));
    axes('Position', [0.05, 0.15, 0.9, 0.75]);
    t = obj.channels(k).storage.dataIndex/obj.sampleFreq;
    plot(t, double(obj.channels(k).storage.I_Q(:,1)))
    set(gca, 'XLim',[1,obj.Tms/1000])
end

function plot_I_P_flag(obj, k)
    figure('Position', screenBlock(1000,300,0.5,0.5));
    axes('Position', [0.05, 0.15, 0.9, 0.75]);
    t = obj.channels(k).storage.dataIndex/obj.sampleFreq;
    plot(t, double(obj.channels(k).storage.I_Q(:,1)))
    hold on
    index = find(obj.channels(k).storage.bitFlag=='H'); %寻找帧头阶段,结尾为[1,0,0,0,1,0,1,1]
    t = obj.channels(k).storage.dataIndex(index)/obj.sampleFreq;
    plot(t, double(obj.channels(k).storage.I_Q(index,1)), 'LineStyle','none', 'Marker','.', 'Color','m')
    index = find(obj.channels(k).storage.bitFlag=='C'); %校验帧头阶段,结尾为[1,0,0,0,1,0,1,1]
    t = obj.channels(k).storage.dataIndex(index)/obj.sampleFreq;
    plot(t, double(obj.channels(k).storage.I_Q(index,1)), 'LineStyle','none', 'Marker','.', 'Color','b')
    index = find(obj.channels(k).storage.bitFlag=='E'); %解析星历阶段
    t = obj.channels(k).storage.dataIndex(index)/obj.sampleFreq;
    plot(t, double(obj.channels(k).storage.I_Q(index,1)), 'LineStyle','none', 'Marker','.', 'Color','r')
    set(gca, 'XLim',[1,obj.Tms/1000])
end

function plot_carrFreq(obj, k)
    figure
    t = obj.channels(k).storage.dataIndex/obj.sampleFreq;
    plot(t, obj.channels(k).storage.carrFreq)
    set(gca, 'XLim',[1,obj.Tms/1000])
    grid on
end

function plot_codeFreq(obj, k)
    figure
    t = obj.channels(k).storage.dataIndex/obj.sampleFreq;
    plot(t, obj.channels(k).storage.codeFreq)
    set(gca, 'XLim',[1,obj.Tms/1000])
    grid on
end