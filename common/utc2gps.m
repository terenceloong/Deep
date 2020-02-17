function t = utc2gps(c, zone)
% UTC时间转化为GPS周和GPS秒
% c:[year, mon, date, hour, min, sec]
% zone:时区,东半球为正,西半球为负
% t:[week,second],GPS周数,从0开始一直加

% datenum(1980,1,6)  = 723186
% datenum(1999,8,22) = 730354
% datenum(2019,4,7)  = 737522

% 根据输入时间设置跳秒
leap = 18; %UTC的跳秒,UTC每跳1s,GPS时间会超前1s

day = datenum(c(1),c(2),c(3)) - 723186; %相对GPS时间起点过了多少天
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