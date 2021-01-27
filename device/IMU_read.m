function imu = IMU_read(filepath)
% 读IMU数据文件,根据文件名前缀调用不同的文件解析函数
% filepath:文件完整路径
% imu数据格式固定,[GPS周内秒.角速度(deg/s),加速度(m/s^2)]

[~, name, ~] = fileparts(filepath); %分离出文件名
prefix = strtok(name,'_'); %文件名前缀

if contains('ADIS16448',prefix)
    imu = IMU_ADI_read(filepath);
    imu(:,2:4) = movmean(imu(:,2:4),5,1); %预处理
    imu(:,5:7) = movmean(imu(:,5:7),4,1);
    imu(:,5:7) = imu(:,5:7) * 9.80665; %加速度单位换成m/s^2
elseif contains('SBG',prefix)
    imu = IMU_SBG_read(filepath);
elseif contains('IMU',prefix)
    imu = IMU_SIM_read(filepath);
else
    error('File error!')
end

end