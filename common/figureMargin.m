function figureMargin(ax, h, scale)
% figure中曲线上下留白
% ax:轴对象
% h:曲线对象
% scale:留白比例

y1 = min(h.YData);
y2 = max(h.YData);
if y2>y1 %曲线不是常值
    ym = (y1+y2)/2; %中值
    yh = (y2-y1)/2; %曲线范围的一半
    set(ax, 'ylim', [ym-yh*(1+scale),ym+yh*(1+scale)])
end

end