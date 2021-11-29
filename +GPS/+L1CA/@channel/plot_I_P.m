function varargout = plot_I_P(obj, varargin)
% 画I_P图

flag = 1;
if nargin==1
    name_str = ['GPS ',sprintf('%d',obj.PRN)];
elseif ischar(varargin{1})
    name_str = ['GPS ',sprintf('%d',obj.PRN),varargin{1}];
elseif isgraphics(varargin{1})
    f = varargin{1};
    flag = 0;
else
    return
end

% 新建figure
if flag==1
    f = figure('Position',screenBlock(1000,300,0.5,0.5), 'Name',name_str);
    axes('Position',[0.05, 0.15, 0.9, 0.75])
    set(gca, 'Box','on', 'NextPlot','add')
    set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
end

% 画图
ax = f.Children(1);
t = obj.storage.dataIndex/obj.sampleFreq;
plot(ax, t, double(obj.storage.I_Q(:,1)))

if nargout>0
    varargout{1} = f; %将图句柄输出
end

end