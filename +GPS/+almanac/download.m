function filename = download(filepath, t)
% 下载GPS历书
% filepath:文件存储路径,结尾不带\
% t:[week,second],GPS周数(从起始周开始的),GPS周内秒数
% http://celestrak.com

% 检查目标文件夹是否存在
if ~exist(filepath,'dir')
    error('File path doesn''t exist!')
end

% 根据周数计算年份
day = 723186 + t(1)*7; %serial date number, datenum(1980,1,6)=723186
DateString = datestr(day); %'dd-mmm-yyyy'
year = DateString(8:11); %年份字符串

% 生成历书文件名,周数取1024的模
week = mod(t(1),1024);
second = t(2);
if second<61440
    w = sprintf('%04d',week);
    s = '061440';
elseif second<147456
    w = sprintf('%04d',week);
    s = '147456';
elseif second<233472
    w = sprintf('%04d',week);
    s = '233472';
elseif second<319488
    w = sprintf('%04d',week);
    s = '319488';
elseif second<405504
    w = sprintf('%04d',week);
    s = '405504';
elseif second<589824
    w = sprintf('%04d',week);
    s = '589824';
else
    w = sprintf('%04d',mod(week+1,1024));
    s = '061440';
end
filename = [filepath,'\',w,'_',s,'.txt'];

% 如果文件不存在,下载历书
if ~exist(filename,'file')
    url = ['http://celestrak.com/GPS/almanac/Yuma/',year,'/almanac.yuma.week',w,'.',s,'.txt'];
    websave(filename, url);
end

end