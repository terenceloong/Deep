function plot_pos(obj)
% 画位置输出

if obj.ns==0 %没有数据直接退出
    return
end

% 时间轴
t = obj.storage.ta - obj.storage.ta(1);
t = t + obj.Tms/1000 - t(end);

%% 正常模式
if obj.state==1
    figure('Name','位置')
    for k=1:3
        subplot(3,1,k)
        plot(t, obj.storage.pos(:,k))
        grid on
        set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
    end
end

%% 紧组合/深组合模式
if obj.state==2 || obj.state==3
    figure('Name','位置')
    for k=1:3
        subplot(3,1,k)
        plot(t, obj.storage.satnav(:,k))
        hold on
        grid on
        plot(t, obj.storage.pos(:,k), 'LineWidth',1)
        set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
    end
end

end