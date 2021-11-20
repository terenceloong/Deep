function filename = download(filepath, date)
% 下载BDS广播星历
% filepath:文件存储路径,结尾不带\
% date:日期,'yyyy-mm-dd',字符串

% BDS broadcast ephemeris
% http://www.csno-tarc.cn/support/downloads

% 检查目标文件夹是否存在
if ~exist(filepath,'dir')
    error('File path doesn''t exist!')
end

% 生成文件名
day_of_year = date2day(date(1:10)); %当前日期是一年的第几天
year = date(1:4); %年份字符串
day = sprintf('%03d', day_of_year); %天数字符串,三位,前面补零
ftppath = ['/brdc/',year,'/']; %ftp路径
ftpfile = ['tarc',day,'0.',year(3:4),'b']; %ftp文件名
filename = [filepath,'\',ftpfile]; %本地星历文件名

% 如果文件已存在,直接返回
if exist(filename,'file')
    return
end

% 下载
% ftpobj = ftp('59.252.100.32', 'tarc', 'gnsscenter'); %连接ftp服务器
ftpobj = ftp('ftp2.csno-tarc.cn', 'pub', 'tarc'); %连接ftp服务器
cd(ftpobj, ftppath); %进入文件夹
mget(ftpobj, ftpfile, filepath); %下载文件,指定存储文件夹
close(ftpobj); %关闭连接

end