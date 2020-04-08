function imu_input(obj, tp, imu)
% IMU数据输入
% tp:下次的定位时间,s
% imu:下次的IMU数据

obj.tp = sec2smu(tp); %[s,ms,us]
obj.imu = imu;

end