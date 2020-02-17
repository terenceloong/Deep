function day = date2day(date)
% 计算输入日期是一年的第几天
% 日期格式:'yyyy-mm-dd',字符串

date0 = [date(1:4),'-01-01']; %年初那天
day = datenum(date,'yyyy-mm-dd') - datenum(date0,'yyyy-mm-dd') + 1;

end