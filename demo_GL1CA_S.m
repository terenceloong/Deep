% GPS L1 C/A单天线接收机测试

clear
clc
fclose('all'); %关闭之前打开的所有文件

%% 选择GNSS数据文件
% default_path = fileread('.\temp\path_data.txt'); %数据文件所在默认路径
% [file, path] = uigetfile([default_path,'\*.dat'], '选择GNSS数据文件'); %文件选择对话框
% if file==0 %取消选择,file返回0,path返回0
%     disp('Invalid file!');
%     return
% end
% if strcmp(file(1:4),'B210')==0
%     error('File error!');
% end
% data_file = [path, file]; %数据文件完整路径,path最后带\

% data_file = 'D:\GNSS\data\20190826\B210_20190826_104744_ch1.dat';
data_file = 'C:\Users\longt\Desktop\B210_20190823_194010_ch1.dat';

%% 主机参数(*)
msToProcess = 10*1000; %处理总时间
sampleOffset = 0*4e6; %抛弃前多少个采样点
sampleFreq = 4e6; %接收机采样频率
blockSize = sampleFreq*0.001; %一个缓存块(1ms)的采样点数
p0 = [45.730952, 126.624970, 212]; %初始位置,不用特别精确

%% 获取接收机初始时间
tf = sscanf(data_file((end-22):(end-8)), '%4d%02d%02d_%02d%02d%02d')'; %数据文件开始采样时间(日期时间向量)
tg = utc2gps(tf, 8); %UTC时间转化为GPS时间
ta = [tg(2),0,0] + sample2dt(sampleOffset, sampleFreq); %接收机初始时间,[s,ms,us]
ta = time_carry(round(ta,2)); %进位,微秒保留2位小数

%% 创建接收机对象(*)
nCoV = GL1CA_S(4e6, [tg(1),ta], msToProcess, p0); %创建对象
nCoV.get_almanac('.\temp\almanac'); %获取历书
% nCoV.set_svList(24); %设置跟踪卫星列表
nCoV.set_svList([10,15,20,24]);
% nCoV.set_svList([]);

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

%% 清除变量
clearvars -except nCoV tf p0 data_file

%% 打印通道日志
nCoV.print_log;

%% 显示跟踪结果
% nCoV.show_trackResult;
nCoV.plot_constellation;

%% 其他
% GPS.visibility('.\temp\almanac', tf, 8, p0, 1); %显示当前可见卫星

%% 保存结果
