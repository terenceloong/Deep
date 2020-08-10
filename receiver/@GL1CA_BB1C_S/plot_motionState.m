function plot_motionState(obj)
% 画运动状态

% 时间轴
t = obj.storage.ta - obj.storage.ta(1);
t = t + obj.Tms/1000 - t(end);

%% 深组合模式
if obj.state==3
    figure('Name','运动状态')
    plot(t, vecnorm(obj.storage.imu(:,1:3),2,2)) %角速度模长
    hold on
    grid on
    plot(t, obj.storage.motion) %运动状态
end

end