% IMU数据生成(使用Matlab工具箱中的IMU模型)

clearvars -except imuGene_conf imuGene_GUIflag
clc

%% IMU数据生成配置预设值
% 使用GUI时外部会生成imuGene_conf,并将imuGene_GUIflag置1
if ~exist('imuGene_GUIflag','var') || imuGene_GUIflag~=1
    imuGene_conf.startTime = [2020,7,27,11,16,14]; %数据开始时间
    imuGene_conf.zone = 8; %时区
    imuGene_conf.dt = 0.01; %IMU采样周期,s
    imuGene_conf.gyroBias = [0.1,0.2,0.3]*1; %陀螺仪零偏,deg/s
    imuGene_conf.gyroInstability = 2.5/3600; %陀螺仪零偏稳定性,deg/s
    imuGene_conf.gyroNoise = 0.15/60; %陀螺仪噪声密度,deg/s/sqrt(Hz)
    imuGene_conf.accBias = [-2,2,-3]*0.01*1; %加速度计零偏,m/s^2
    imuGene_conf.accInstability = 13e-6*10; %加速度计零偏稳定性,m/s^2
    imuGene_conf.accNoise = 0.037/60; %加速度计噪声密度,m/s^2/sqrt(Hz)
    imuGene_conf.trajName = 'traj004'; %轨迹名
end
if exist('imuGene_GUIflag','var')
    imuGene_GUIflag = 0;
end

%% 参数
startTime = imuGene_conf.startTime; %数据开始时间
zone = imuGene_conf.zone; %时区
dt = imuGene_conf.dt; %IMU采样周期,s
gyroBias = imuGene_conf.gyroBias; %陀螺仪零偏,deg/s
gyroInstability = imuGene_conf.gyroInstability; %陀螺仪零偏稳定性,deg/s
gyroNoise = imuGene_conf.gyroNoise; %陀螺仪噪声密度,deg/s/sqrt(Hz)
accBias = imuGene_conf.accBias; %加速度计零偏,m/s^2
accInstability = imuGene_conf.accInstability; %加速度计零偏稳定性,m/s^2
accNoise = imuGene_conf.accNoise; %加速度计噪声密度,m/s^2/sqrt(Hz)
trajName = imuGene_conf.trajName; %轨迹名

%% 生成传感器对象
paramsG = gyroparams;
paramsG.ConstantBias = gyroBias /180*pi; %rad/s
paramsG.BiasInstability = gyroInstability /180*pi; %rad/s
paramsG.NoiseDensity = gyroNoise /180*pi; %rad/s/sqrt(Hz)
paramsA = accelparams;
paramsA.ConstantBias = accBias; %m/s^2
paramsA.BiasInstability = accInstability; %m/s^2
paramsA.NoiseDensity = accNoise; %m/s^2/sqrt(Hz)
IMU_obj = imuSensor('accel-gyro');
IMU_obj.SampleRate = 1/dt;
IMU_obj.Accelerometer = paramsA;
IMU_obj.Gyroscope = paramsG;

%% 加载轨迹
load(['~temp\traj\',trajName,'.mat'])

%% 检查采样周期是否匹配
if mod(dt/trajGene_conf.dt,1)~=0
    error('Sample time mismatch!')
end

%% 数据开始时间
startTime_gps = UTC2GPS(startTime, zone); %GPS时间
tow = startTime_gps(2); %周内秒

%% 添加误差
m = dt / trajGene_conf.dt; %取数跳点数
n = (size(traj,1)-1)/m + 1; %IMU数据个数
imu = [tow+(0:n-1)'*dt, traj(1:m:end,13:18)]; %从轨迹中取角速度和加速度
[imu(:,5:7), imu(:,2:4)] = IMU_obj(-imu(:,5:7), imu(:,2:4)/180*pi);
imu(:,2:4) = imu(:,2:4) /pi*180;
imu(:,7) = imu(:,7) - 9.81;

%% 保存文件
startTime_str = sprintf('%4d%02d%02d_%02d%02d%02d', startTime);
fileID = fopen(['~temp\data\IMU_',startTime_str,'_',trajName(end-2:end),'.txt'], 'w');
for k=1:n
    fprintf(fileID, '%10.3f %13.6f %13.6f %13.6f %10.3f %10.3f %10.3f\r\n' ,imu(k,:));
end
fclose(fileID);

%% 清除变量
clearvars -except traj imu imuGene_conf

%% 画图
imuGene_plot;