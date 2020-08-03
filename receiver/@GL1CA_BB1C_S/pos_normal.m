function pos_normal(obj)
% 正常定位



% 更新下次定位时间
obj.tp = timeCarry(obj.tp + [0,obj.dtpos,0]);

end