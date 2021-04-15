function plot_vel(obj)
% 画速度输出

if obj.ns==0 %没有数据直接退出
    return
end

% 时间轴
t = obj.storage.ta - obj.storage.ta(end) + obj.Tms/1000;

% 纯卫星导航解算结果
figure('Name','速度')
for k=1:3
    subplot(3,1,k)
    plot(t, obj.storage.satnav(:,k+3))
    hold on
    grid on
    set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
end

% 滤波结果
if obj.state==2 || obj.state==3 || obj.state==4
    for k=1:3
        subplot(3,1,k)
        plot(t, obj.storage.vel(:,k), 'LineWidth',0.5)
    end
    figure('Name','速度误差')
    for k=1:3
        subplot(3,1,k)
        plot(t, obj.storage.satnav(:,k+3)-obj.storage.vel(:,k))
        grid on
    end
end

end