function varargout = plot_I_Q(obj, varargin)
% 画I/Q图,可以新建图画,也可以在别的图上叠加
% 当输入参数不存在时,新建figure
% 当输入参数为字符串时,新建figure,并在图名后边添加这个字符串
% 当输入参数为figure句柄时,在输入figure上画

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
    f = figure('Name',name_str);
	axes('Box','on', 'NextPlot','add')
    axis equal
end

% 画图
ax = f.Children(1);
plot(ax, obj.storage.I_Q(1001:end,1), obj.storage.I_Q(1001:end,4), 'LineStyle','none', 'Marker','.')

if nargout>0
    varargout{1} = f; %将图句柄输出
end

end