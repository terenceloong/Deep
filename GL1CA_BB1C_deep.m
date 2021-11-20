%% GPS L1 C/A & BDS B1C单天线深组合

%%
clear
clc
fclose('all'); %关闭之前打开的所有文件

Ts = 600; %总处理时间,s
To = 0; %偏移时间,s
GPSflag = 1;
BDSflag = 1;
GPSlist = [];
BDSlist = [19,21,22,34,38];
p0 = [45.730952, 126.624970, 212]; %大致的初始位置
% p0 = [38.0463, 114.4358, 100];
psi0 = 38.1; %初始航向,deg
arm = [-0.1,0,0]; %杆臂,IMU指向天线

%% 选择IMU数据文件
[file, path] = uigetfile('*.dat;*.txt', '选择IMU数据文件'); %文件选择对话框
if ~ischar(file)
    error('File error!')
end
imu = IMU_read([path,file]); %读IMU数据文件
imuN = size(imu,1); %IMU数据行数
gyro0 = mean(imu(1:200,2:4)); %计算初始陀螺零偏

%% 选择GNSS数据文件
valid_prefix = 'B210-'; %文件名有效前缀
[file, path] = uigetfile('*.dat', '选择GNSS数据文件'); %文件选择对话框
if ~ischar(file) || ~contains(valid_prefix, strtok(file,'_'))
    error('File error!')
end
data_file = [path, file]; %数据文件完整路径,path最后带\

%% 主机参数
% 根据实际情况修改.
msToProcess = Ts*1000; %处理总时间
sampleOffset = To*4e6; %抛弃前多少个采样点
sampleFreq = 4e6; %接收机采样频率
blockSize = sampleFreq*0.001; %一个缓存块(1ms)的采样点数

%% 获取接收机初始时间
[~, filename] = strtok(file,'_'); %文件名去掉前缀剩下的部分
filetime = filename(2:16); %文件时间
tf = sscanf(filetime, '%4d%02d%02d_%02d%02d%02d')'; %数据文件开始时间(日期时间向量)
% GPS时
tg = UTC2GPS(tf, 8); %UTC时间转化为GPS时间,周+秒
tag = [tg(2),0,0] + sample2dt(sampleOffset, sampleFreq); %接收机初始时间,[s,ms,us]
tag = timeCarry(round(tag,2)); %进位,微秒保留2位小数
% 北斗时
tb = UTC2BDT(tf, 8); %UTC时间转化为BDT时间,周+秒
% tab = [tb(2),0,0] + sample2dt(sampleOffset, sampleFreq);
% tab = timeCarry(round(tab,2));

%% 获取历书
% 需指定历书存储的文件夹.
almanac_file_GPS = GPS.almanac.download('~temp\almanac', tg); %下载历书
almanac_GPS = GPS.almanac.read(almanac_file_GPS); %读历书
date = sprintf('%4d-%02d-%02d', tf(1),tf(2),tf(3)); %当前日期
almanac_BDS = [];
if datenum(tf(1),tf(2),tf(3))>=datenum(2020,5,18) %2020年5月18号后才有全的历书
    almanac_file_BDS = BDS.almanac.download('~temp\almanac', date); %下载历书
    almanac_BDS = BDS.almanac.read(almanac_file_BDS); %读历书
    index = ismember(almanac_BDS(:,1), [19:30,32:46]);
    almanac_BDS = almanac_BDS(index,:); %只要北斗三号卫星的历书
end

%% 接收机配置
% 根据实际配置修改.
receiver_conf.Tms = msToProcess; %接收机总运行时间,ms
receiver_conf.sampleFreq = sampleFreq; %采样频率,Hz
receiver_conf.blockSize = blockSize; %一个缓存块(1ms)的采样点数
receiver_conf.blockNum = 50; %缓存块的数量
receiver_conf.GPSweek = tg(1); %当前GPS周数
receiver_conf.BDSweek = tb(1); %当前北斗周数
receiver_conf.ta = tag; %接收机初始时间,[s,ms,us],使用GPS时间作为时间基准
receiver_conf.CN0Thr = [37,33,30,18]; %载噪比阈值
receiver_conf.GPSflag = GPSflag; %是否启用GPS
receiver_conf.BDSflag = BDSflag; %是否启用北斗
%-------------------------------------------------------------------------%
receiver_conf.GPS.almanac = almanac_GPS; %历书
receiver_conf.GPS.eleMask = 10; %高度角阈值
receiver_conf.GPS.svList = GPSlist; %跟踪卫星列表
receiver_conf.GPS.acqTime = 2; %捕获所用的数据长度,ms
receiver_conf.GPS.acqThreshold = 1.4; %捕获阈值,最高峰与第二大峰的比值
receiver_conf.GPS.acqFreqMax = 5e3; %最大搜索频率,Hz
%-------------------------------------------------------------------------%
receiver_conf.BDS.almanac = almanac_BDS; %历书
receiver_conf.BDS.eleMask = 10; %高度角阈值
receiver_conf.BDS.svList = BDSlist; %跟踪卫星列表
receiver_conf.BDS.acqThreshold = 1.4; %捕获阈值,最高峰与第二大峰的比值
receiver_conf.BDS.acqFreqMax = 5e3; %最大搜索频率,Hz
%-------------------------------------------------------------------------%
receiver_conf.p0 = p0; %初始位置,纬经高
receiver_conf.dtpos = 10; %定位时间间隔,ms

%% 导航滤波器参数
para.dt = 0.01; %s,根据IMU采样周期设置
para.p0 = [0,0,0];
para.v0 = [0,0,0];
para.a0 = [psi0,0,0]; %deg
para.P0_att = 1; %deg
para.P0_vel = 1; %m/s
para.P0_pos = 15; %m
para.P0_dtr = 5e-8; %s
para.P0_dtv = 3e-9; %s/s
para.P0_gyro = 0.2; %deg/s
para.P0_acc = 2e-3; %g
para.Q_gyro = 0.2; %deg/s
para.Q_acc = 2e-3; %g
para.Q_dtv = 0.01e-9; %1/s
para.Q_dg = 0.01*1; %deg/s/s
para.Q_da = 0.1e-3; %g/s
para.sigma_gyro = 0.15; %deg/s
para.arm = arm; %m
para.gyro0 = gyro0; %deg/s
if strcmp(file(1:3),'SIM')
    para.windupFlag = 0;
else
    para.windupFlag = 1;
end

%% 创建接收机对象
nCoV = GL1CA_BB1C_S(receiver_conf);

%% 预置星历
ephemeris_file = ['~temp\ephemeris\',filetime,'.mat']; %文件名
nCoV.set_ephemeris(ephemeris_file);

%% 打开文件,创建进度条
fileID = fopen(data_file, 'r');
fseek(fileID, round(sampleOffset*4), 'bof'); %不取整可能出现文件指针移不过去
if int64(ftell(fileID))~=int64(sampleOffset*4) %检查文件指针是否移过去了
    error('Sample offset error!')
end
waitbar_str = ['s/',num2str(msToProcess/1000),'s']; %进度条中不变的字符串
f = waitbar(0, ['0',waitbar_str]);

%% 接收机运行
tic
for t=1:msToProcess
    if mod(t,1000)==0 %1s步进
        waitbar(t/msToProcess, f, [sprintf('%d',t/1000),waitbar_str]); %更新进度条
    end
    data = fread(fileID, [2,blockSize], 'int16'); %从文件读数据
    nCoV.run(data); %接收机处理数据
    %---------------------------------------------------------------------%
    if nCoV.state==3 %深组合时,进行一次定位后为其设置下次定位时间和IMU数据
        if isnan(nCoV.tp(1)) %定位后tp会变成NaN
            ki = ki+1; %IMU索引加1
            if ki>imuN %IMU数据超范围
                break
            end
            nCoV.imu_input(imu(ki,1), imu(ki,2:7)); %输入IMU数据
        end
    elseif nCoV.state==1 %当接收机初始化完成后进入深组合
        ki = find(imu(:,1)>nCoV.ta*[1;1e-3;1e-6], 1); %IMU索引
        if isempty(ki) || (imu(ki,1)-nCoV.ta(1))>1
            error('Data mismatch!')
        end
        nCoV.imu_input(imu(ki,1), imu(ki,2:7)); %输入IMU数据
        para.p0 = nCoV.pos;
        para.v0 = nCoV.vel;
        nCoV.navFilter = filter_single(para); %初始化导航滤波器
        nCoV.vectorMode = 2; %设置矢量跟踪模式
        nCoV.channel_vector; %通道切换矢量跟踪环路
        nCoV.state = 3; %接收机进入深组合
    end
    %---------------------------------------------------------------------%
end
nCoV.clean_storage;
nCoV.get_result;
toc

%% 关闭文件,关闭进度条
fclose(fileID);
close(f);

%% 保存星历
nCoV.save_ephemeris(ephemeris_file);

%% 清除变量
clearvars -except data_file receiver_conf nCoV tf p0 imu

%% 画交互星座图
nCoV.interact_constellation;

%% 保存结果
save('~temp\result\result.mat')