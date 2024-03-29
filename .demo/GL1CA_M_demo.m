%% GPS L1 C/A多天线接收机例程

%%
clear
clc
fclose('all'); %关闭之前打开的所有文件

Ts = 60; %总处理时间,s
To = 0; %偏移时间,s
svList = []; %[10,15,20,24]
p0 = [45.730952, 126.624970, 212]; %大致的初始位置
% p0 = [38.05, 114.55222, 132];

%% 选择GNSS数据文件
valid_prefix = 'B210-SIM-'; %文件名有效前缀
[file, path] = uigetfile('*.dat', '选择GNSS数据文件'); %文件选择对话框
if ~ischar(file) || ~contains(valid_prefix, strtok(file,'_'))
    error('File error!')
end
if ~(strcmp(file(end-6:end-4),'ch1'))
    error('File error!')
end
data_file_1 = [path, file(1:end-7), 'ch1.dat']; %数据文件完整路径,path最后带\
data_file_2 = [path, file(1:end-7), 'ch2.dat'];

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
receiver_conf.anN = 2; %天线数量
receiver_conf.blockSize = blockSize; %一个缓存块(1ms)的采样点数
receiver_conf.blockNum = 50; %缓存块的数量
receiver_conf.week = tg(1); %当前GPS周数
receiver_conf.ta = ta; %接收机初始时间,[s,ms,us]
receiver_conf.CN0Thr = [37,33,30,18]; %载噪比阈值
receiver_conf.almanac = almanac; %历书
receiver_conf.eleMask = 10; %高度角阈值
receiver_conf.svList = svList; %跟踪卫星列表
receiver_conf.acqTime = 2; %捕获所用的数据长度,ms
receiver_conf.acqThreshold = 1.4; %捕获阈值,最高峰与第二大峰的比值
receiver_conf.acqFreqMax = 5e3; %最大搜索频率,Hz
receiver_conf.p0 = p0; %初始位置,纬经高
receiver_conf.dtpos = 10; %定位时间间隔,ms

%% 创建接收机对象
nCoV = GL1CA_M(receiver_conf);

%% 预置星历
% 可选操作,可以提前进行定位.
% 需指定星历存储的文件夹.
% 星历文件可以不存在,调用时会自动创建.
% 注释掉这段时同时要注释掉后面的保存星历.
ephemeris_file = ['~temp\ephemeris\',filetime,'.mat']; %文件名
nCoV.set_ephemeris(ephemeris_file);

%% 打开文件,创建进度条
fileID_1 = fopen(data_file_1, 'r');
fseek(fileID_1, round(sampleOffset*4), 'bof'); %不取整可能出现文件指针移不过去
if int64(ftell(fileID_1))~=int64(sampleOffset*4) %检查文件指针是否移过去了
    error('Sample offset error!')
end
fileID_2 = fopen(data_file_2, 'r');
fseek(fileID_2, round(sampleOffset*4), 'bof'); %不取整可能出现文件指针移不过去
if int64(ftell(fileID_2))~=int64(sampleOffset*4) %检查文件指针是否移过去了
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
    data1 = fread(fileID_1, [2,blockSize], 'int16'); %从文件读数据
    data2 = fread(fileID_2, [2,blockSize], 'int16');
    nCoV.run(cat(3,data1,data2)); %接收机处理数据
end
nCoV.clean_storage;
% nCoV.get_result;
toc

%% 关闭文件,关闭进度条
fclose(fileID_1);
fclose(fileID_2);
close(f);

%% 保存星历
% 与前面的预置星历对应.
nCoV.save_ephemeris(ephemeris_file);

%% 清除变量
data_file = data_file_1;
clearvars -except data_file receiver_conf nCoV tf p0

%% 画交互星座图
nCoV.interact_constellation;

%% 保存结果
save('~temp\result\result.mat')