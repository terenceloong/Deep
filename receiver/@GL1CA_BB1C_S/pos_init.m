function pos_init(obj)
% 初始化定位



% 更新下次定位时间
obj.tp = timeCarry(obj.tp + [0,obj.dtpos,0]);

end