% IMU数据生成

clearvars -except imuGene_conf imuGene_GUIflag
clc

%% IMU数据生成配置预设值
% 使用GUI时外部会生成imuGene_conf,并将imuGene_GUIflag置1
if ~exist('imuGene_GUIflag','var') || imuGene_GUIflag~=1
    imuGene_conf.startTime = [2020,7,27,11,16,14]; %数据开始时间
    imuGene_conf.zone = 8; %时区
    imuGene_conf.dt = 0.01; %IMU采样周期,s
    imuGene_conf.gyroBias = [0.1,0.2,0.3]*1; %陀螺仪零偏,deg/s
    imuGene_conf.accBias = [-2,2,-3]*0.01*1; %加速度计零偏,m/s^2
    imuGene_conf.gyroSigma = 0.03*1; %陀螺仪噪声标准差,deg/s
    imuGene_conf.accSigma = 0.01*1; %加速度计噪声标准差,m/s^2
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
accBias = imuGene_conf.accBias; %加速度计零偏,m/s^2
gyroSigma = imuGene_conf.gyroSigma; %陀螺仪噪声标准差,deg/s
accSigma = imuGene_conf.accSigma; %加速度计噪声标准差,m/s^2
trajName = imuGene_conf.trajName; %轨迹名

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
imu(:,2:4) = imu(:,2:4) + ones(n,1)*gyroBias + randn(n,3)*gyroSigma;
imu(:,5:7) = imu(:,5:7) + ones(n,1)*accBias + randn(n,3)*accSigma;
% imu(:,1) = imu(:,1) + 0.003; %模拟时延

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