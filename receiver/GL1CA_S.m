classdef GL1CA_S < handle
% GPS L1 C/A单天线接收机
% 可以配置的数:可见星高度角阈值
    
    % 主机参数
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
    end
    % 时钟参数
    properties (GetAccess = public, SetAccess = private)
        tms            %接收机当前运行时间,ms
        week           %GPS周数
        ta             %接收机时间,GPS周内秒数,[s,ms,us]
        deltaFreq      %接收机时钟频率误差,无量纲,钟快为正
    end
    % 历书
    properties (GetAccess = public, SetAccess = private)
        almanac        %所有卫星的历书
        aziele         %使用历书计算的卫星方位角高度角
        eleMask = 10   %高度角阈值
    end
    % 通道参数
    properties (GetAccess = public, SetAccess = private)
        svList         %跟踪卫星列表
        chN            %跟踪通道数量
        channels       %跟踪通道
    end
    % 定位参数
    properties (GetAccess = public, SetAccess = private)
        iono           %电离层校正参数
        pos            %接收机位置,纬经高
        vel            %接收机速度,北东地
    end
    % 数据存储
%     properties (GetAccess = public, SetAccess = private)
%         
%     end
    
    methods
        %% 构造函数
        function obj = GL1CA_S(sampleFreq, t0, Tms, p0)
            % sampleFreq:采样频率,Hz
            % t0:接收机初始时间,[week,s,ms,us]
            % Tms:接收机总运行时间,ms
            % p0:初始位置,纬经高
            %----设置主机参数
            obj.Tms = Tms;
            obj.sampleFreq = sampleFreq;
            obj.blockSize = sampleFreq*0.001; %一个缓存块固定为1ms
            obj.blockNum = 40; %缓存块数量固定一个值
            obj.buffI = zeros(obj.blockSize,obj.blockNum); %矩阵形式,每一列为一个块
            obj.buffQ = zeros(obj.blockSize,obj.blockNum);
            obj.buffSize = obj.blockSize * obj.blockNum;
            obj.blockPoint = 1;
            obj.buffHead = 0;
            %----设置时钟参数
            obj.tms = 0;
            obj.week = t0(1);
            obj.ta = t0(2:4);
            obj.deltaFreq = 0;
            %----设置初始位置
            obj.pos = p0;
            obj.vel = [0,0,0];
            %----申请数据存储空间
        end
        
        %% 运行函数
        function run(obj, data)
            % data:采样数据,两行,分别为I/Q数据,原始数据类型
            %----往数据缓存存数
            obj.buffI(:,obj.blockPoint) = data(1,:); %往数据缓存的指定块存数,不用加转置,自动变成列向量
            obj.buffQ(:,obj.blockPoint) = data(2,:);
            obj.buffHead = obj.blockPoint * obj.blockSize; %最新数据的位置
            obj.blockPoint = obj.blockPoint + 1; %指向下一块
            if obj.blockPoint>obj.blockNum
                obj.blockPoint = 1;
            end
            obj.tms = obj.tms + 1;
            %----更新接收机时间
            fs = obj.sampleFreq * (1+obj.deltaFreq); %修正后的采样频率
            obj.ta = timeCarry(obj.ta + sample2dt(obj.blockSize, fs));
            %----捕获
            if mod(obj.tms,1000)==0 %1s搜索一次
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
            %----跟踪
            for k=1:obj.chN
                if obj.channels(k).state==0 %如果通道未激活,跳过跟踪
                    continue
                end
                while 1
                    % 判断是否有完整的跟踪数据
                    if mod(obj.buffHead-obj.channels(k).trackDataHead,obj.buffSize)>(obj.buffSize/2)
                        break
                    end
                    n1 = obj.channels(k).trackDataTail;
                    n2 = obj.channels(k).trackDataHead;
                    if n2>n1
                        obj.channels(k).track(obj.buffI(n1:n2), obj.buffQ(n1:n2), obj.deltaFreq);
                    else
                        obj.channels(k).track([obj.buffI(n1:end),obj.buffI(1:n2)], ...
                                              [obj.buffQ(n1:end),obj.buffQ(1:n2)], obj.deltaFreq);
                    end
                    iono0 = obj.channels(k).parse; %解析导航电文
                    if ~isempty(iono0)
                        obj.iono = iono0; %提取电离层参数
                    end
                end
            end
            %----定位
        end
        
        %% 获取历书
        function get_almanac(obj, filepath)
            % filepath:历书存储路径,结尾不带\
            t = [obj.week, obj.ta(1)]; %当前时间
            filename = GPS.almanac.download(filepath, t); %下载历书,得到完整文件名
            obj.almanac = GPS.almanac.read(filename); %读历书文件
            %----使用历书计算所有卫星方位角高度角
            index = find(obj.almanac(:,2)==0); %获取健康卫星的行号
            n = length(index); %健康卫星个数
            obj.aziele = zeros(n,3); %[ID,azi,ele]
            obj.aziele(:,1) = obj.almanac(index,1); %ID
            obj.aziele(:,2:3) = aziele_almanac(obj.almanac(index,3:end), t, obj.pos); %[azi,ele]
        end
        
        %% 设置跟踪卫星列表
        function set_svList(obj, svList)
            obj.svList = svList;
            if isempty(obj.svList) %如果列表为空,使用历书计算的可见卫星
                if isempty(obj.almanac) %如果历书不存在,报错
                    error('Almanac doesn''t exist!')
                end
                obj.svList = obj.aziele(obj.aziele(:,3)>obj.eleMask,1)'; %选取高度角大于阈值的卫星
            end
            %----创建通道对象
            obj.chN = length(obj.svList);
            obj.channels = GPS.L1CA.channel(obj.sampleFreq, obj.buffSize, obj.svList(1), obj.Tms);
            % 先创建一个对象用来确定channel的数据类型,后面才能用索引往下续
            for k=2:obj.chN
                obj.channels(k) = GPS.L1CA.channel(obj.sampleFreq, obj.buffSize, obj.svList(k), obj.Tms);
            end
            obj.channels = obj.channels'; %转成列向量
        end
        
        %% 清理数据储存
        function clean_storage(obj)
            for k=1:obj.chN
                obj.channels(k).clean_storage;
            end
        end
        
        %% 预设星历
        function set_ephemeris(obj, filename)
            load(filename, 'ephemeris') %加载预存的星历
            if ~isfield(ephemeris, 'GPS_ephe') %如果星历中不存在GPS星历,创建空星历
                ephemeris.GPS_ephe = NaN(25,32);
                ephemeris.GPS_iono = NaN(8,1);
                save(filename, 'ephemeris') %保存到文件中
            end
            obj.iono = ephemeris.GPS_iono; %提取电离层校正参数
            for k=1:obj.chN %为每个通道赋星历
                obj.channels(k).ephe = ephemeris.GPS_ephe(:,obj.channels(k).PRN);
            end
        end
        
        %% 保存星历
        function save_ephemeris(obj, filename)
            load(filename, 'ephemeris') %加载预存的星历
            ephemeris.GPS_iono = obj.iono; %保存电离层校正参数
            for k=1:obj.chN %提取有星历通道的星历
                if ~isnan(obj.channels(k).ephe(1))
                    ephemeris.GPS_ephe(:,obj.channels(k).PRN) = obj.channels(k).ephe;
                end
            end
            save(filename, 'ephemeris') %保存到文件中
        end
        
        %% 打印通道日志
        function print_log(obj)
            for k=1:obj.chN
                fprintf('PRN %d\n', obj.channels(k).PRN); %使用\r\n会多一个空行
                n = length(obj.channels(k).log); %通道日志的行数
                if n>1 %行数大于1,日志有内容
                    for m=2:n %逐行打印
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
            end
        end
        
        %% 显示星座图
        function plot_constellation(obj)
            %----挑选高度角大于0的卫星
            index = find(obj.aziele(:,3)>0); %高度角大于0的卫星索引
            n = length(index); %卫星个数
            PRN = obj.aziele(index,1);
            azi = mod(obj.aziele(index,2),360)/180*pi; %方位角转成弧度,0~360度
            ele = obj.aziele(index,3); %高度角,deg
            %----统计跟踪到的卫星
            svTrack = obj.svList([obj.channels.ns]~=0);
            %----画图
            figure
            ax = polaraxes; %创建极坐标轴
            hold(ax, 'on')
            ax.RLim = [0,90]; %高度角范围
            ax.RDir = 'reverse'; %高度角里面是90度
            ax.RTick = [0,15,30,45,60,75,90]; %高度角刻度
            ax.ThetaDir = 'clockwise'; %顺时针方位角增加
            ax.ThetaZeroLocation = 'top'; %方位角0在上
            for k=1:n %处理所有高度角大于0的卫星
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