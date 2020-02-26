% GPS L1 C/A单天线接收机例程

clear
clc
fclose('all'); %关闭之前打开的所有文件

%% 选择GNSS数据文件
% default_path = fileread('~temp\path_data.txt'); %数据文件所在默认路径
% [file, path] = uigetfile([default_path,'\*.dat'], '选择GNSS数据文件'); %文件选择对话框
% if file==0 %取消选择,file返回0,path返回0
%     disp('Invalid file!');
%     return
% end
% if strcmp(file(1:4),'B210')==0
%     error('File error!');
% end
% data_file = [path, file]; %数据文件完整路径,path最后带\

data_file = 'C:\Users\longt\Desktop\B210_20190823_194010_ch1.dat'; %指定文件,用于测试

%% 主机参数(*)
msToProcess = 10*1000; %处理总时间
sampleOffset = 0*4e6; %抛弃前多少个采样点
sampleFreq = 4e6; %接收机采样频率
blockSize = sampleFreq*0.001; %一个缓存块(1ms)的采样点数
p0 = [45.730952, 126.624970, 212]; %初始位置,不用特别精确

%% 获取接收机初始时间
tf = sscanf(data_file((end-22):(end-8)), '%4d%02d%02d_%02d%02d%02d')'; %数据文件开始采样时间(日期时间向量)
tg = UTC2GPS(tf, 8); %UTC时间转化为GPS时间
ta = [tg(2),0,0] + sample2dt(sampleOffset, sampleFreq); %接收机初始时间,[s,ms,us]
ta = timeCarry(round(ta,2)); %进位,微秒保留2位小数

%% 获取历书
almanac_file = GPS.almanac.download('~temp\almanac', tg); %下载历书
almanac = GPS.almanac.read(almanac_file); %读历书

%% 接收机配置(*)
receiver_conf.Tms = msToProcess; %接收机总运行时间,ms
receiver_conf.sampleFreq = sampleFreq; %采样频率,Hz
receiver_conf.blockSize = blockSize; %一个缓存块(1ms)的采样点数
receiver_conf.blockNum = 40; %缓存块的数量
receiver_conf.week = tg(1); %当前GPS周数
receiver_conf.ta = ta; %接收机初始时间,[s,ms,us]
receiver_conf.p0 = p0; %初始位置,纬经高
receiver_conf.almanac = almanac; %历书
receiver_conf.eleMask = 10; %高度角阈值
receiver_conf.svList = [10,15,20,24]; %跟踪卫星列表[10,15,20,24]
receiver_conf.acqTime = 2; %捕获所用的数据长度,ms
receiver_conf.acqThreshold = 1.4; %捕获阈值,最高峰与第二大峰的比值
receiver_conf.acqFreqMax = 5e3; %最大搜索频率,Hz
receiver_conf.dtpos = 10; %定位时间间隔,ms

%% 创建接收机对象
nCoV = GL1CA_S(receiver_conf);

%% (预置星历)
% 不是必要的操作,只是可以提前进行定位
% 星历文件可以不存在,调用时会自动创建
% 注释掉这段时同时要注释掉后面的保存星历
ephemeris_file = ['~temp\ephemeris\',data_file((end-22):(end-8)),'.mat']; %文件名
nCoV.set_ephemeris(ephemeris_file);

%% 打开文件,创建进度条
fileID = fopen(data_file, 'r');
fseek(fileID, round(sampleOffset*4), 'bof'); %不取整可能出现文件指针移不过去
if int64(ftell(fileID))~=int64(sampleOffset*4) %检查文件指针是否移过去了
    error('Sample offset error!');
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

%% (保存星历)
nCoV.save_ephemeris(ephemeris_file);

%% 清除变量
clearvars -except data_file receiver_conf nCoV almanac_path tf p0

%% 打印通道日志
nCoV.print_log;

%% 显示跟踪结果
% nCoV.show_trackResult;
nCoV.plot_constellation;

%% (其他)
% GPS.visibility(almanac_path, tf, 8, p0, 1); %显示当前可见卫星

%% 保存结果
