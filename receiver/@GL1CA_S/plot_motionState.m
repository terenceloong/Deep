function plot_motionState(obj)
% 画运动状态

if obj.ns==0 %没有数据直接退出
    return
end

% 时间轴
t = obj.storage.ta - obj.storage.ta(end) + obj.Tms/1000;

if obj.state==2 || obj.state==3
    figure('Name','运动状态')
    omega = obj.storage.imu(:,1:3)/pi*180 - ones(obj.ns,1)*obj.navFilter.motion.gyro0;
    plot(t, vecnorm(omega,2,2)) %角速度模长
    hold on
    grid on
    plot(t, vecnorm(obj.storage.vel,2,2)) %速度模长
    plot(t, obj.storage.motion, 'Color',[0.466,0.674,0.188], 'LineWidth',2) %运动状态
    set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
end

end