function imu = IMU_SBG_read(filepath)
% 导入SBG IMU数据,固定100Hz
% 第一列为GPS周内秒数,s
% 角速度单位deg/s,加速度单位m/s^2

% 打开文件
fileID = fopen(filepath, 'r');

% 统计行数
fgetl(fileID); %忽略前两行
fgetl(fileID);
n = 0;
while ~feof(fileID)
    fgetl(fileID);
    n = n + 1;
end

% 读取数据
data = zeros(n,12);
fseek(fileID, 0, 'bof'); %从头开始
fgetl(fileID); %忽略前两行
fgetl(fileID);
for k=1:n
    tline = fgetl(fileID);
    data(k,:) = sscanf(tline,'%d-%d-%d %d:%d:%f %f %f %f %f %f %f');
end

% 关闭文件
fclose(fileID);

% 转化成GPS时间
t0 = UTC2GPS(data(1,1:6), 0); %第一个数的GPS时间,周和秒
imu = [t0(2)+(0:n-1)'*0.01, data(:,7:12)];

% 检验是否丢数
t1 = UTC2GPS(data(end,1:6), 0); %最后一个数的GPS时间,周和秒
if imu(end,1)~=t1(2)
    error('Data lost!')
end

end