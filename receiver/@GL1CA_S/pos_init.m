function pos_init(obj)
% 初始化定位

% 获取卫星测量信息
satmeas = obj.get_satmeas;

% 卫星导航解算
sv = satmeas(~isnan(satmeas(:,1)),:); %选星
satnav = satnavSolve(sv, obj.rp);
dtr = satnav(13); %接收机钟差,s

% 更新接收机位置速度
if ~isnan(satnav(1))
    obj.pos = satnav(1:3);
    obj.rp  = satnav(4:6);
    obj.vel = satnav(7:9);
    obj.vp  = satnav(10:12);
end

% 接收机时钟初始化
if ~isnan(dtr)
    if abs(dtr)>0.1e-3 %钟差大于0.1ms,修正接收机时间
        obj.ta = obj.ta - sec2smu(dtr);
        obj.ta = timeCarry(obj.ta);
        obj.tp(1) = obj.ta(1); %更新下次定位时间
        obj.tp(2) = ceil(obj.ta(2)/obj.dtpos) * obj.dtpos;
        obj.tp = timeCarry(obj.tp);
    else %钟差小于0.1ms,初始化结束
        obj.state = 1;
    end
end

% 更新下次定位时间
obj.tp = timeCarry(obj.tp + [0,obj.dtpos,0]);

end