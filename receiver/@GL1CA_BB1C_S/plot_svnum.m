function plot_svnum(obj)
% 画可见卫星数量

if obj.ns==0 %没有数据直接退出
    return
end

% 时间轴
t = obj.storage.ta - obj.storage.ta(end) + obj.Tms/1000;

figure('Name','可见卫星数量')
if obj.GPSflag+obj.BDSflag==1
    plot(t, obj.result.svnumALL(:,2))
    grid on
    set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
elseif obj.GPSflag+obj.BDSflag==2
    svnum_table = table(t,obj.result.svnumGPS(:,2), ...
                          obj.result.svnumBDS(:,2), ...
                          obj.result.svnumALL(:,2), ...
                        'VariableNames',{'t','GPS','BDS','GPS+BDS'});
    stackedplot(svnum_table, 'XVariable','t')
    grid on
    set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
end

end