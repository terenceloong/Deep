function download(filepath, date)
% 下载GPS广播星历
% filepath:文件存储路径,结尾不带\
% date:日期,'yyyy-mm-dd',字符串
% 使用前需将winRAR安装路径加入系统环境变量

% GPS broadcast ephemeris
% https://cddis.nasa.gov/Data_and_Derived_Products/GNSS/broadcast_ephemeris_data.html

% 生成文件名
day_of_year = date2day(date(1:10)); %当前日期是一年的第几天
year = date(1:4); %年份字符串
day = sprintf('%03d', day_of_year); %天数字符串,三位,前面补零
ftppath = ['/gnss/data/daily/',year,'/brdc/']; %ftp路径
filename = ['brdc',day,'0.',year(3:4),'n.Z'];

% 下载
ftpobj = ftp('cddis.nasa.gov'); %连接ftp服务器
cd(ftpobj, ftppath); %进入文件夹
mget(ftpobj, filename, filepath); %下载文件,指定存储文件夹
close(ftpobj); %关闭连接

% 检查是否下载成功,解压
filename = [filepath,'\',filename]; %包含路径的文件名
if exist(filename,'file')==2 %检查是否下载成功
    disp('Download succeeded!')
    system(['winrar x -o+ "',filename,'" "',filepath,'"']); %-o+选项,覆盖文件
    delete(filename) %删除压缩文件
else
    disp('Download failed!')
end

end