function interact_constellation(obj)
% 画交互星座图

% 如果没有历书不画图
if isempty(obj.almanac)
    disp('Almanac doesn''t exist!')
    return
end

% 挑选高度角大于0的卫星
index = find(obj.aziele(:,3)>0); %高度角大于0的卫星索引
PRN = obj.aziele(index,1);
azi = mod(obj.aziele(index,2),360)/180*pi; %方位角转成弧度,0~360度
ele = obj.aziele(index,3); %高度角,deg

% 统计跟踪到的卫星
svTrack = obj.svList([obj.channels.ns]~=0);

% 创建figure
f = figure('Name','Constellation');
c = uicontextmenu; %创建目录
f.UIContextMenu = c; %目录加到figure上,在figure空白处右键弹出

% 创建figure目录项(*)
uimenu(c, 'MenuSelectedFcn',@figureCallback, 'Text','Print log');
uimenu(c, 'MenuSelectedFcn',@figureCallback, 'Text','Plot trackResult');

% 创建极坐标轴
ax = polaraxes; %创建极坐标轴
ax.NextPlot = 'add';
ax.RLim = [0,90]; %高度角范围
ax.RDir = 'reverse'; %高度角里面是90度
ax.RTick = [0,15,30,45,60,75,90]; %高度角刻度
ax.ThetaDir = 'clockwise'; %顺时针方位角增加
ax.ThetaZeroLocation = 'top'; %方位角0在上

% 画图
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
    % 创建目录项(*)
    uimenu(c, 'MenuSelectedFcn',@scatterCallback, 'UserData',ch, 'Text','trackResult');
    uimenu(c, 'MenuSelectedFcn',@scatterCallback, 'UserData',ch, 'Text','I_Q');
    uimenu(c, 'MenuSelectedFcn',@scatterCallback, 'UserData',ch, 'Text','I_P');
    uimenu(c, 'MenuSelectedFcn',@scatterCallback, 'UserData',ch, 'Text','I_P(flag)');
    uimenu(c, 'MenuSelectedFcn',@scatterCallback, 'UserData',ch, 'Text','carrFreq');
    uimenu(c, 'MenuSelectedFcn',@scatterCallback, 'UserData',ch, 'Text','codeFreq');
    uimenu(c, 'MenuSelectedFcn',@scatterCallback, 'UserData',ch, 'Text','carrAcc');
end
            
    %% 在figure上右键的回调函数
    function figureCallback(source, ~)
        switch source.Text
            case 'Print log'
                obj.print_all_log;
            case 'Plot trackResult'
                obj.plot_all_trackResult;
        end
    end
            
    %% 在卫星上右键的回调函数
    function scatterCallback(source, ~)
        % 必须要有两个输入参数(source, callbackdata),名字不重要
        % 第一个返回matlab.ui.container.Menu对象
        % 第二个返回ui.eventdata.ActionData
        kc = source.UserData; %通道号
        switch source.Text
            case 'trackResult'
                plot_trackResult(obj.channels(kc))
            case 'I_Q'
                plot_I_Q(obj.channels(kc))
            case 'I_P'
                plot_I_P(obj.channels(kc))
            case 'I_P(flag)'
                plot_I_P_flag(obj.channels(kc))
            case 'carrFreq'
                plot_carrFreq(obj.channels(kc))
            case 'codeFreq'
                plot_codeFreq(obj.channels(kc))
            case 'carrAcc'
                plot_carrAcc(obj.channels(kc))
        end
    end

end