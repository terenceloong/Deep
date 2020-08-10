function plot_svnum(obj)
% 画可见卫星数量

% 时间轴
t = obj.storage.ta - obj.storage.ta(1);
t = t + obj.Tms/1000 - t(end);

figure('Name','可见卫星数量')
if obj.GPSflag+obj.BDSflag==1
    plot(t, obj.result.svnumALL(:,2))
    grid on
elseif obj.GPSflag+obj.BDSflag==2
    svnum_table = table(t,obj.result.svnumGPS(:,2), ...
                          obj.result.svnumBDS(:,2), ...
                          obj.result.svnumALL(:,2), ...
                        'VariableNames',{'t','GPS','BDS','GPS+BDS'});
    stackedplot(svnum_table, 'XVariable','t')
    grid on
end

end