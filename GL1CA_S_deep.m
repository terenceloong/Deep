%% GPS L1 C/A单天线深组合

%%
clear
clc
fclose('all'); %关闭之前打开的所有文件

%% 选择IMU数据文件
imu = IMU_read(0);

%% 选择GNSS数据文件
valid_prefix = 'B210-'; %文件名有效前缀
[file, path] = uigetfile('*.dat', '选择GNSS数据文件'); %文件选择对话框
if ~ischar(file) || ~contains(valid_prefix, strtok(file,'_'))
    error('File error!')
end
data_file = [path, file]; %数据文件完整路径,path最后带\

% data_file = 'C:\Users\longt\Desktop\B210_20190823_194010_ch1.dat'; %指定文件,用于测试

%% 主机参数
% 根据实际情况修改.
msToProcess = 60*1000; %处理总时间
sampleOffset = 0*4e6; %抛弃前多少个采样点
sampleFreq = 4e6; %接收机采样频率
blockSize = sampleFreq*0.001; %一个缓存块(1ms)的采样点数
p0 = [45.730952, 126.624970, 212]; %初始位置,不用特别精确

%% 获取接收机初始时间
tf = sscanf(data_file((end-22):(end-8)), '%4d%02d%02d_%02d%02d%02d')'; %数据文件开始时间(日期时间向量)
tg = UTC2GPS(tf, 8); %UTC时间转化为GPS时间
ta = [tg(2),0,0] + sample2dt(sampleOffset, sampleFreq); %接收机初始时间,[s,ms,us]
ta = timeCarry(round(ta,2)); %进位,微秒保留2位小数

%% 获取历书
% 需指定历书存储的文件夹.
almanac_file = GPS.almanac.download('~temp\almanac', tg); %下载历书
almanac = GPS.almanac.read(almanac_file); %读历书

%% 接收机配置
% 根据实际配置修改.
receiver_conf.Tms = msToProcess; %接收机总运行时间,ms
receiver_conf.sampleFreq = sampleFreq; %采样频率,Hz
receiver_conf.blockSize = blockSize; %一个缓存块(1ms)的采样点数
receiver_conf.blockNum = 40; %缓存块的数量
receiver_conf.week = tg(1); %当前GPS周数
receiver_conf.ta = ta; %接收机初始时间,[s,ms,us]
receiver_conf.p0 = p0; %初始位置,纬经高
receiver_conf.almanac = almanac; %历书
receiver_conf.eleMask = 10; %高度角阈值
receiver_conf.svList = []; %跟踪卫星列表[10,15,20,24]
receiver_conf.acqTime = 2; %捕获所用的数据长度,ms
receiver_conf.acqThreshold = 1.4; %捕获阈值,最高峰与第二大峰的比值
receiver_conf.acqFreqMax = 5e3; %最大搜索频率,Hz
receiver_conf.dtpos = 10; %定位时间间隔,ms

%% 创建接收机对象
nCoV = GL1CA_S(receiver_conf);

%% 预置星历
% 可选操作,可以提前进行定位.
% 需指定星历存储的文件夹.
% 星历文件可以不存在,调用时会自动创建.
% 注释掉这段时同时要注释掉后面的保存星历.
ephemeris_file = ['~temp\ephemeris\',data_file((end-22):(end-8)),'.mat']; %文件名
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
    % 深组合模式切换,IMU数据输入
    if nCoV.state==2
        % 进入深组合模式后,进行一次定位后为其设置下次定位时间和IMU数据
        if isnan(nCoV.tp(1)) %定位后tp会变成NaN
            ki = ki+1; %IMU索引加1
            nCoV.imu_input(imu(ki,1), imu(ki,2:7)); %输入IMU数据
        end
    elseif nCoV.state==1
        % 当接收机初始化完成后进入深组合模式
        ki = find(imu(:,1)>nCoV.ta*[1;1e-3;1e-6], 1); %IMU索引
        if isempty(ki) || (imu(ki,1)-nCoV.ta(1))>1
            error('Data mismatch!')
        end
        nCoV.imu_input(imu(ki,1), imu(ki,2:7)); %输入IMU数据
        nCoV.enter_deep; %进入深组合模式
    end
end
nCoV.clean_storage;
nCoV.get_result;
toc

%% 关闭文件,关闭进度条
fclose(fileID);
close(f);

%% 保存星历
% 与前面的预置星历对应.
nCoV.save_ephemeris(ephemeris_file);

%% 清除变量
clearvars -except data_file receiver_conf nCoV almanac_path tf p0 imu

%% 画交互星座图
nCoV.interact_constellation;

%% 其他

% nCoV.print_all_log; %打印通道日志
% nCoV.plot_all_trackResult; %显示跟踪结果
% GPS.visibility('~temp\almanac', tf, 8, p0, 1); %显示当前可见卫星一段时间的轨迹

%% 保存结果
save('~temp\result.mat')