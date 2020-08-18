% 使用USRP采集GNSS数据

clear
clc

%% 配置
exe_path = 'C:\Users\longt\Desktop\gnss_rx\x64\Release'; %可执行文件路径
data_path = 'C:\Users\longt\Desktop\GNSS data'; %数据存储路径
sample_time = 300; %采样时间,s
channel = 2; %通道数量
gain = 36; %增益,dB
ref = 1; %是否使用外部时钟
pps = 0; %是否使用外部PPS,暂时不使用

%% 生成命令
exe_opt = [exe_path,'\gnss_rx'];
data_opt = [' -p "',data_path,'"'];
name_opt = ' -n';
time_opt = [' -t ',num2str(sample_time)];
gain_opt = [' -g ',num2str(gain)];
if channel==1
    channel_opt = [];
else
    channel_opt = ' -d';
end
if ref==0
    ref_opt = [];
else
    ref_opt = ' -r';
end

cmd = [exe_opt, data_opt, name_opt, time_opt, gain_opt, channel_opt, ref_opt]; %控制台命令
system(cmd); %执行系统命令

clearvars