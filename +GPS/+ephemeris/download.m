function filename = download(filepath, date)
% 下载GPS广播星历
% filepath:文件存储路径,结尾不带\
% date:日期,'yyyy-mm-dd',字符串
% 使用前需将winRAR安装路径加入系统环境变量

% GPS broadcast ephemeris
% https://cddis.nasa.gov/Data_and_Derived_Products/GNSS/broadcast_ephemeris_data.html

%%
% % 检查目标文件夹是否存在
% if ~exist(filepath,'dir')
%     error('File path doesn''t exist!')
% end
% 
% % 生成文件名
% day_of_year = date2day(date(1:10)); %当前日期是一年的第几天
% year = date(1:4); %年份字符串
% day = sprintf('%03d', day_of_year); %天数字符串,三位,前面补零
% ftppath = ['/gnss/data/daily/',year,'/brdc/']; %ftp路径
% ftpfile = ['brdc',day,'0.',year(3:4),'n.Z']; %ftp文件名
% Zfile = [filepath,'\',ftpfile]; %本地压缩文件名
% filename = Zfile(1:end-2); %本地星历文件名
% 
% % 如果文件已存在,直接返回
% if exist(filename,'file')
%     return
% end
% 
% % 下载
% ftpobj = ftp('cddis.nasa.gov'); %连接ftp服务器
% cd(ftpobj, ftppath); %进入文件夹
% mget(ftpobj, ftpfile, filepath); %下载文件,指定存储文件夹
% close(ftpobj); %关闭连接
% 
% % 解压文件
% system(['winrar x -o+ "',Zfile,'" "',filepath,'"']); %-o+选项,覆盖文件
% delete(Zfile) %删除压缩文件

%%
% ftp://cddis.nasa.gov在2020年10月31日就不能匿名登录了
% 换ftp://gssc.esa.int

% 检查目标文件夹是否存在
if ~exist(filepath,'dir')
    error('File path doesn''t exist!')
end

% 生成文件名
day_of_year = date2day(date(1:10)); %当前日期是一年的第几天
year = date(1:4); %年份字符串
day = sprintf('%03d', day_of_year); %天数字符串,三位,前面补零
ftppath = ['/gnss/data/daily/',year,'/brdc/']; %ftp路径
ftpfile = ['brdc',day,'0.',year(3:4),'n.Z']; %ftp文件名
Zfile = [filepath,'\',ftpfile]; %本地压缩文件名
filename = Zfile(1:end-2); %本地星历文件名

% 如果文件已存在,直接返回
if exist(filename,'file')
    return
end

% 下载
ftpobj = ftp('gssc.esa.int'); %连接ftp服务器
cd(ftpobj, ftppath); %进入文件夹
filelist = dir(ftpobj); %提取文件列表
filelist = {filelist.name}'; %只要文件名,存成元胞数组列向量
if any(strcmp(filelist,ftpfile)) %检查是否存在文件
    mget(ftpobj, ftpfile, filepath); %下载文件,指定存储文件夹
    close(ftpobj); %关闭连接
else
    ftpfile = [ftpfile(1:end-1),'gz']; %试以gz结尾的文件
    if any(strcmp(filelist,ftpfile)) %检查是否存在文件
        mget(ftpobj, ftpfile, filepath); %下载文件,指定存储文件夹
        close(ftpobj); %关闭连接
        Zfile = [filepath,'\',ftpfile]; %本地压缩文件名
    else
        close(ftpobj); %关闭连接
        error('File doesn''t exist!')
    end
end

% 解压文件
status = system(['winrar x -o+ "',Zfile,'" "',filepath,'"']); %-o+选项,覆盖文件
if status==0 %0表示执行成功
    delete(Zfile) %删除压缩文件
else
    warning('系统环境变量中没有WinRAR路径,需添加,并手动解压文件')
end

end