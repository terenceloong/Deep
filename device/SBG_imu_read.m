function varargout = SBG_imu_read(plotflag)
% 导入SBG IMU数据,固定100Hz
% 第一列为GPS周内秒数,s
% 角速度单位deg/s,加速度单位m/s^2

% 选择文件
[file, path] = uigetfile('*.txt', '选择SBG数据文件'); %文件选择对话框
if ~ischar(file)
    error('File error!')
end
filename = [path, file]; %数据文件完整路径,path最后带\

% 打开文件
fileID = fopen(filename);

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

% 转化成GPS时间
t0 = UTC2GPS(data(1,1:6), 0); %第一个数的GPS时间，周和秒
imu_data = [t0(2)+(0:n-1)'*0.01, data(:,7:12)];

% 检验是否丢数
t1 = UTC2GPS(data(end,1:6), 0); %最后一个数的GPS时间，周和秒
if imu_data(end,1)~=t1(2)
    error('Data lost!')
end

% 关闭文件
fclose(fileID);

% 画图
if plotflag
    figure
    t = imu_data(:,1) - imu_data(1,1);
    subplot(3,2,1)
    plot(t,imu_data(:,2))
    grid on
    set(gca, 'xlim', [t(1),t(end)])
    subplot(3,2,3)
    plot(t,imu_data(:,3))
    grid on
    set(gca, 'xlim', [t(1),t(end)])
    subplot(3,2,5)
    plot(t,imu_data(:,4))
    grid on
    set(gca, 'xlim', [t(1),t(end)])
    subplot(3,2,2)
    plot(t,imu_data(:,5))
    grid on
    set(gca, 'xlim', [t(1),t(end)])
    subplot(3,2,4)
    plot(t,imu_data(:,6))
    grid on
    set(gca, 'xlim', [t(1),t(end)])
    subplot(3,2,6)
    plot(t,imu_data(:,7))
    grid on
    set(gca, 'xlim', [t(1),t(end)])
end

% 输出
if nargout==1
    varargout{1} = imu_data;
end

end