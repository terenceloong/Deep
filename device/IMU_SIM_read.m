function imu = IMU_SIM_read(filepath)
% 读仿真生成的IMU数据文件

fileID = fopen(filepath, 'r');
dataArray = textscan(fileID, '%10.3f %13.6f %13.6f %13.6f %10.3f %10.3f %10.3f\r\n');
imu = [dataArray{1:end}];
fclose(fileID);

end