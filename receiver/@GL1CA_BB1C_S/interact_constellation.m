function interact_constellation(obj)
% 画交互星座图

% 创建figure
f = figure('Name','Constellation');
c = uicontextmenu; %创建目录
f.UIContextMenu = c; %目录加到figure上,在figure空白处右键弹出

% 创建figure目录项(*)
uimenu(c, 'MenuSelectedFcn',{@menuCallback,obj,'print_all_log'}, 'Text','Print all log');
% uimenu(c, 'MenuSelectedFcn',{@menuCallback,obj,'plot_all_trackResult'}, 'Text','Plot all trackResult');
uimenu(c, 'MenuSelectedFcn',{@menuCallback,obj,'plot_all_I_Q'}, 'Text','Print all I/Q');
uimenu(c, 'MenuSelectedFcn',{@menuCallback,obj,'plot_all_I_P'}, 'Text','Print all I_P');
uimenu(c, 'MenuSelectedFcn',{@menuCallback,obj,'plot_all_carrNco'}, 'Text','Print all carrNco');
uimenu(c, 'MenuSelectedFcn',{@menuCallback,obj,'plot_all_carrAcc'}, 'Text','Print all carrAcc');
uimenu(c, 'MenuSelectedFcn',{@menuCallback,obj,'plot_sv_3d'}, 'Text','Plot 3D', 'Separator','on');
uimenu(c, 'MenuSelectedFcn',{@menuCallback,obj,'plot_svnum'}, 'Text','Plot svnum');
uimenu(c, 'MenuSelectedFcn',{@menuCallback,obj,'plot_motionState'}, 'Text','Plot motionState');
uimenu(c, 'MenuSelectedFcn',{@menuCallback,obj,'plot_df'}, 'Text','Plot df', 'Separator','on');
uimenu(c, 'MenuSelectedFcn',{@menuCallback,obj,'plot_pos'}, 'Text','Plot pos', 'Separator','on');
uimenu(c, 'MenuSelectedFcn',{@menuCallback,obj,'plot_vel'}, 'Text','Plot vel');
uimenu(c, 'MenuSelectedFcn',{@menuCallback,obj,'plot_att'}, 'Text','Plot att');
uimenu(c, 'MenuSelectedFcn',{@menuCallback,obj,'plot_bias_gyro'}, 'Text','Plot bias_gyro');
uimenu(c, 'MenuSelectedFcn',{@menuCallback,obj,'plot_bias_acc'}, 'Text','Plot bias_acc');
uimenu(c, 'MenuSelectedFcn',{@menuCallback,obj,'kml_output'}, 'Text','KML output', 'Separator','on');

% 创建极坐标轴
ax = polaraxes; %创建极坐标轴
ax.NextPlot = 'add'; %hold on
ax.RLim = [0,90]; %高度角范围
ax.RDir = 'reverse'; %高度角里面是90度
% ax.RTick = [0,15,30,45,60,75,90]; %高度角刻度
ax.ThetaDir = 'clockwise'; %顺时针方位角增加
ax.ThetaZeroLocation = 'top'; %方位角0在上

% 创建一个滑动条,改变高度角显示范围
sl = uicontrol;
sl.Style = 'slider';
sl.Position = [15,15,120,15];
sl.Max = 80;
sl.Min = 0;
sl.SliderStep = [2,8]/80;
sl.Callback = @changeEleRange;
    function changeEleRange(src, ~)
        ax.RLim = [floor(src.Value),90];
    end

%% GPS部分
if obj.GPSflag==1
    % 如果没有历书不画图
    if isempty(obj.GPS.almanac)
        disp('GPS almanac doesn''t exist!')
        return
    end
    
    % 挑选高度角大于0的卫星
    index = obj.GPS.aziele(:,3)>0; %高度角大于0的卫星索引
    PRN = obj.GPS.aziele(index,1);
    azi = obj.GPS.aziele(index,2)/180*pi; %方位角转成弧度
    ele = obj.GPS.aziele(index,3); %高度角,deg
    
    % 统计跟踪到的卫星
    svTrack = obj.GPS.svList([obj.GPS.channels.ns]~=0);
    
    % 画图
    for k=1:length(PRN) %处理所有高度角大于0的卫星
        % 低高度角卫星,透明
        if ele(k)<obj.GPS.eleMask
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
        % 跟踪到的卫星,边框加粗,设置右键菜单
        polarscatter(azi(k),ele(k), 220, 'MarkerFaceColor',[65,180,250]/255, ...
                     'MarkerEdgeColor',[127,127,127]/255, 'LineWidth',2)
        t = text(azi(k),ele(k),num2str(PRN(k)), 'HorizontalAlignment','center', ...
                                                'VerticalAlignment','middle');
        c = uicontextmenu; %创建目录
        t.UIContextMenu = c; %目录加到text上,因为文字覆盖了圆圈
        objch = obj.GPS.channels(obj.GPS.svList==PRN(k)); %通道对象
        % 创建目录项(*)
        uimenu(c, 'MenuSelectedFcn',{@menuCallback,objch,'plot_trackResult'}, 'Text','trackResult');
        uimenu(c, 'MenuSelectedFcn',{@menuCallback,objch,'plot_I_Q'}, 'Text','I/Q', 'Separator','on');
        uimenu(c, 'MenuSelectedFcn',{@menuCallback,objch,'plot_I_P'}, 'Text','I_P');
        uimenu(c, 'MenuSelectedFcn',{@menuCallback,objch,'plot_I_P_flag'}, 'Text','I_P(flag)');
        uimenu(c, 'MenuSelectedFcn',{@menuCallback,objch,'plot_codeFreq'}, 'Text','codeFreq', 'Separator','on');
        uimenu(c, 'MenuSelectedFcn',{@menuCallback,objch,'plot_carrFreq'}, 'Text','carrFreq', 'Separator','on');
        uimenu(c, 'MenuSelectedFcn',{@menuCallback,objch,'plot_carrNco'}, 'Text','carrNco');
        uimenu(c, 'MenuSelectedFcn',{@menuCallback,objch,'plot_carrAcc'}, 'Text','carrAcc');
        uimenu(c, 'MenuSelectedFcn',{@menuCallback,objch,'plot_codeDisc'}, 'Text','codeDisc', 'Separator','on');
        uimenu(c, 'MenuSelectedFcn',{@menuCallback,objch,'plot_carrDisc'}, 'Text','carrDisc');
        uimenu(c, 'MenuSelectedFcn',{@menuCallback,objch,'plot_freqDisc'}, 'Text','freqDisc');
        uimenu(c, 'MenuSelectedFcn',{@menuCallback,objch,'plot_quality'}, 'Text','quality', 'Separator','on');
    end
end

%% BDS部分
if obj.BDSflag==1
    % 如果没有历书不画图
    if isempty(obj.BDS.almanac)
        disp('BDS almanac doesn''t exist!')
        return
    end
    
    % 挑选高度角大于0的卫星
    index = obj.BDS.aziele(:,3)>0; %高度角大于0的卫星索引
    PRN = obj.BDS.aziele(index,1);
    azi = obj.BDS.aziele(index,2)/180*pi; %方位角转成弧度
    ele = obj.BDS.aziele(index,3); %高度角,deg
    
    % 统计跟踪到的卫星
    svTrack = obj.BDS.svList([obj.BDS.channels.ns]~=0);
    
    % 画图
    for k=1:length(PRN) %处理所有高度角大于0的卫星
        % 低高度角卫星,透明
        if ele(k)<obj.BDS.eleMask
            polarscatter(azi(k),ele(k), 220, 'MarkerFaceColor',[255,65,65]/255, ...
                         'MarkerEdgeColor',[127,127,127]/255, 'MarkerFaceAlpha',0.5)
            text(azi(k),ele(k),num2str(PRN(k)), 'HorizontalAlignment','center', ...
                                                'VerticalAlignment','middle');
            continue
        end
        % 没跟踪的卫星,边框正常
        if ~ismember(PRN(k),svTrack)
            polarscatter(azi(k),ele(k), 220, 'MarkerFaceColor',[255,65,65]/255, ...
                         'MarkerEdgeColor',[127,127,127]/255)
            text(azi(k),ele(k),num2str(PRN(k)), 'HorizontalAlignment','center', ...
                                                'VerticalAlignment','middle');
            continue
        end
        % 跟踪到的卫星,边框加粗,设置右键菜单
        polarscatter(azi(k),ele(k), 220, 'MarkerFaceColor',[255,65,65]/255, ...
                     'MarkerEdgeColor',[127,127,127]/255, 'LineWidth',2)
        t = text(azi(k),ele(k),num2str(PRN(k)), 'HorizontalAlignment','center', ...
                                                'VerticalAlignment','middle');
        c = uicontextmenu; %创建目录
        t.UIContextMenu = c; %目录加到text上,因为文字覆盖了圆圈
        objch = obj.BDS.channels(obj.BDS.svList==PRN(k)); %通道对象
        % 创建目录项(*)
        uimenu(c, 'MenuSelectedFcn',{@menuCallback,objch,'plot_trackResult'}, 'Text','trackResult');
        uimenu(c, 'MenuSelectedFcn',{@menuCallback,objch,'plot_I_Q'}, 'Text','I_Q', 'Separator','on');
        uimenu(c, 'MenuSelectedFcn',{@menuCallback,objch,'plot_I_P'}, 'Text','I_P');
        uimenu(c, 'MenuSelectedFcn',{@menuCallback,objch,'plot_I_P_flag'}, 'Text','I_P(flag)');
        uimenu(c, 'MenuSelectedFcn',{@menuCallback,objch,'plot_codeFreq'}, 'Text','codeFreq', 'Separator','on');
        uimenu(c, 'MenuSelectedFcn',{@menuCallback,objch,'plot_carrFreq'}, 'Text','carrFreq', 'Separator','on');
        uimenu(c, 'MenuSelectedFcn',{@menuCallback,objch,'plot_carrNco'}, 'Text','carrNco');
        uimenu(c, 'MenuSelectedFcn',{@menuCallback,objch,'plot_carrAcc'}, 'Text','carrAcc');
        uimenu(c, 'MenuSelectedFcn',{@menuCallback,objch,'plot_codeDisc'}, 'Text','codeDisc', 'Separator','on');
        uimenu(c, 'MenuSelectedFcn',{@menuCallback,objch,'plot_carrDisc'}, 'Text','carrDisc');
        uimenu(c, 'MenuSelectedFcn',{@menuCallback,objch,'plot_freqDisc'}, 'Text','freqDisc');
        uimenu(c, 'MenuSelectedFcn',{@menuCallback,objch,'plot_quality'}, 'Text','quality', 'Separator','on');
    end
end

    %% 右键菜单的回调函数
    function menuCallback(varargin)
        % 使用可变输入参数,头两个参数是固定的
        % 第一个参数为matlab.ui.container.Menu对象
        % 第二个参数为ui.eventdata.ActionData
        % 第三个参数为类对象
        % 第四个参数为需要调用的类成员函数字符串(不带参数)
        eval(['varargin{3}.',varargin{4},';'])
    end

end