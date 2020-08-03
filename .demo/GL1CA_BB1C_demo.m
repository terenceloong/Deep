%% GPS L1 C/A & BDS B1C单天线接收机例程

%%
clear
clc
fclose('all'); %关闭之前打开的所有文件

%% 选择GNSS数据文件
% valid_prefix = 'B210-'; %文件名有效前缀
% [file, path] = uigetfile('*.dat', '选择GNSS数据文件'); %文件选择对话框
% if ~ischar(file) || ~contains(valid_prefix, strtok(file,'_'))
%     error('File error!')
% end
% data_file = [path, file]; %数据文件完整路径,path最后带\

% data_file = 'C:\Users\longt\Desktop\B210_20190823_194010_ch1.dat'; %指定文件,用于测试
data_file = 'C:\Users\longt\Desktop\GNSS data\B210_20200727_111615_ch1.dat';

%% 主机参数
% 根据实际情况修改.
msToProcess = 10*1000; %处理总时间
sampleOffset = 0*4e6; %抛弃前多少个采样点
sampleFreq = 4e6; %接收机采样频率
blockSize = sampleFreq*0.001; %一个缓存块(1ms)的采样点数
p0 = [45.730952, 126.624970, 212]; %初始位置,不用特别精确

%% 获取接收机初始时间
tf = sscanf(data_file((end-22):(end-8)), '%4d%02d%02d_%02d%02d%02d')'; %数据文件开始时间(日期时间向量)
% GPS时
tg = UTC2GPS(tf, 8); %UTC时间转化为GPS时间,周+秒
tag = [tg(2),0,0] + sample2dt(sampleOffset, sampleFreq); %接收机初始时间,[s,ms,us]
tag = timeCarry(round(tag,2)); %进位,微秒保留2位小数
% 北斗时
tb = UTC2BDT(tf, 8); %UTC时间转化为BDT时间,周+秒
tab = [tb(2),0,0] + sample2dt(sampleOffset, sampleFreq);
tab = timeCarry(round(tab,2));

%% 获取历书
% 需指定历书存储的文件夹.
almanac_file_GPS = GPS.almanac.download('~temp\almanac', tg); %下载历书
almanac_GPS = GPS.almanac.read(almanac_file_GPS); %读历书
date = sprintf('%4d-%02d-%02d', tf(1),tf(2),tf(3)); %当前日期
almanac_file_BDS = BDS.almanac.download('~temp\almanac', date); %下载历书
almanac_BDS = BDS.almanac.read(almanac_file_BDS); %读历书
index = ismember(almanac_BDS(:,1), [19:30,32:46]);
almanac_BDS = almanac_BDS(index,:); %只要北斗三号卫星的历书

%% 接收机配置
% 根据实际配置修改.
receiver_conf.Tms = msToProcess; %接收机总运行时间,ms
receiver_conf.sampleFreq = sampleFreq; %采样频率,Hz
receiver_conf.blockSize = blockSize; %一个缓存块(1ms)的采样点数
receiver_conf.blockNum = 100; %缓存块的数量
receiver_conf.GPSflag = 1; %是否启用GPS
receiver_conf.BDSflag = 1; %是否启用北斗
%-------------------------------------------------------------------------%
receiver_conf.GPS.week = tg(1); %当前GPS周数
receiver_conf.GPS.ta = tag; %接收机初始GPS时间,[s,ms,us]
receiver_conf.GPS.almanac = almanac_GPS; %历书
receiver_conf.GPS.eleMask = 10; %高度角阈值
receiver_conf.GPS.svList = []; %跟踪卫星列表,[10,15,20,24]
receiver_conf.GPS.acqTime = 2; %捕获所用的数据长度,ms
receiver_conf.GPS.acqThreshold = 1.4; %捕获阈值,最高峰与第二大峰的比值
receiver_conf.GPS.acqFreqMax = 5e3; %最大搜索频率,Hz
%-------------------------------------------------------------------------%
receiver_conf.BDS.week = tb(1); %当前北斗周数
receiver_conf.BDS.ta = tab; %接收机初始BDS时间,[s,ms,us]
receiver_conf.BDS.almanac = almanac_BDS; %历书
receiver_conf.BDS.eleMask = 10; %高度角阈值
receiver_conf.BDS.svList = [19,20,29,35,38,40,44]; %跟踪卫星列表,[19,20,29,35,38,40,44]
receiver_conf.BDS.acqThreshold = 1.4; %捕获阈值,最高峰与第二大峰的比值
receiver_conf.BDS.acqFreqMax = 5e3; %最大搜索频率,Hz
%-------------------------------------------------------------------------%
receiver_conf.p0 = p0; %初始位置,纬经高
receiver_conf.dtpos = 10; %定位时间间隔,ms

%% 创建接收机对象
nCoV = GL1CA_BB1C_S(receiver_conf);

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
end
nCoV.clean_storage;
toc

%% 关闭文件,关闭进度条
fclose(fileID);
close(f);

%% 清除变量
clearvars -except data_file receiver_conf nCoV tf p0

%% 画交互星座图
nCoV.interact_constellation;