function t = UTC2BDT(c, zone)
% UTC时间转化为BDT周和BDT秒
% c:[year, mon, day, hour, min, sec]
% zone:时区,东半球为正,西半球为负
% t:[week,second]

% datenum(2006,1,1) = 732678

% 根据输入时间设置跳秒
leap = 4; %UTC的跳秒,UTC每跳1s,BDT会超前1s

day = datenum(c(1),c(2),c(3)) - 732678; %相对BDT时间起点过了多少天
week = floor(day/7);
second = (day-week*7)*86400 + c(4)*3600 + c(5)*60 + floor(c(6)); %86400=24*3600
second = second - zone*3600 + leap;
if second<0
    second = second + 604800; %604800=7*24*3600
    week = week - 1;
elseif second>=604800
    second = second - 604800;
    week = week + 1;
end
t = [week, second];

end