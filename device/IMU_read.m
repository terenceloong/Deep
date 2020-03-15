function varargout = IMU_read(plotflag)
% 解析IMU数据,将时间戳转化为GPS时间
% 时间单位s,角速度单位deg/s,加速度单位g
% plotflag:是否画图标志,0/1
% 函数形式,使用对话框选择文件
% 使用可变参数输出,使该程序可以直接运行,无输出

%% 读文件
valid_prefix = 'ADIS16448-IMU5210-'; %文件名有效前缀
[file, path] = uigetfile('*.dat', '选择IMU数据文件'); %文件选择对话框
if ~ischar(file) || ~contains(valid_prefix, strtok(file,'_'))
    error('File error!')
end
fileID = fopen([path,file], 'r');
stream = fread(fileID, 'uint8=>uint8');
fclose(fileID);

%% 解析原始数据
% [cnt, year,mon,day, hour,min,sec, TIM3, wx,wy,wz, fx,fy,fz, temp, PPS_error]
% 每帧27字节,16个数
% cnt每帧数据加1,TIM3每0.1ms加1,PPS_error每检测到一次PPS错误加1
n = length(stream); %总字节数
data = zeros(ceil(n/27),16); %解析的原始数据
k = 1; %字节索引
m = 1; %数据存储行
while 1
    if k+26>n %剩下的数据已经构不成完整帧,退出
        break
    end
    if stream(k)==85 && stream(k+26)==170 %帧头0x55,帧尾0xAA
        buff = stream(k+(0:26)); %提取一帧
        data(m,1) = buff(3); %cnt
        data(m,2) = buff(4); %year
        data(m,3) = buff(5); %mon
        data(m,4) = buff(6); %day
        data(m,5) = buff(7); %hour
        data(m,6) = buff(8); %min
        data(m,7) = buff(9); %sec
        data(m,8) = typecast(buff(10:11),'uint16'); %TIM3
        data(m,16) = buff(26); %PPS_error
        switch buff(2) %根据设备号进行数据转换
            case 0
                data(m,10) =  double(typecast(buff(12:13),'int16')) /32768*300;
                data(m,9)  =  double(typecast(buff(14:15),'int16')) /32768*300;
                data(m,11) = -double(typecast(buff(16:17),'int16')) /32768*300;
                data(m,13) =  double(typecast(buff(18:19),'int16')) /32768*10;
                data(m,12) =  double(typecast(buff(20:21),'int16')) /32768*10;
                data(m,14) = -double(typecast(buff(22:23),'int16')) /32768*10;
                data(m,15) =  double(typecast(buff(24:25),'int16')) /10; %温度
            case 1
                data(m,10) = -double(typecast(buff(12:13),'int16')) /50;
                data(m,9)  = -double(typecast(buff(14:15),'int16')) /50;
                data(m,11) = -double(typecast(buff(16:17),'int16')) /50;
                data(m,13) = -double(typecast(buff(18:19),'int16')) /1200;
                data(m,12) = -double(typecast(buff(20:21),'int16')) /1200;
                data(m,14) = -double(typecast(buff(22:23),'int16')) /1200;
                data(m,15) =  double(typecast(buff(24:25),'int16')) *0.07386 + 31; %温度
        end
        m = m+1; %指向下一存储行
        k = k+27; %指向下一帧
    else
        k = k+1; %指向下一字节
    end
end
if m==1
    error('No data!')
end
data(m:end,:) = []; %删除空白数据
data(:,2) = data(:,2) + 2000; %年份加2000

%% 校验cnt,PPS_error
cnt_diff = mod(diff(data(:,1)),256);
if sum(cnt_diff~=1)~=0 %cnt间隔必须是1
    error('cnt error!')
end
if sum(data(:,16)~=data(1,16))~=0 %PPS_error必须都相同
    error('PPS_error error!')
end

%% 统计采样时间
if plotflag
    sample_time = mod(diff(data(:,8)),10000); %采样时间,只能为99,100,101,单位,0.1ms
    figure
    plot(sample_time)
    title('采样时间')
    sample_time_mean = cumsum(sample_time) ./ (1:length(sample_time))'; %平均采样时间,理论上为10ms,实际可能略高或略低
    figure
    plot(sample_time_mean)
    grid on
    title('平均采样时间')
end

%% 提取IMU数据,将时间戳转化为GPS周内秒数
n = length(data);
imu_data = zeros(n,7); %IMU数据,[t, wx,wy,wz, fx,fy,fz], deg/s, g
imu_data(:,2:7) = data(:,9:14);
t0 = UTC2GPS(data(1,2:7), 0); %第一个点的时间,[week,second],时区是0
ts = t0(2);
imu_data(1,1) = ts + data(1,8)/10000;
for k=2:n
    if data(k,7)~=data(k-1,7) %与前面一个点的秒数不一样,秒数加1
        ts = ts+1;
    end
    imu_data(k,1) = ts + data(k,8)/10000;
end

%% 检查时间是否正确
time_diff = diff(imu_data(:,1));
if sum(time_diff>0.0102)~=0 || sum(time_diff<0.0098)~=0 %相邻时间应该在10ms
    error('time error!')
end

%% 画IMU数据
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

%% 输出
if nargout==1
    varargout{1} = imu_data;
end

end