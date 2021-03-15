%% 观察当时间按周内秒数取模时计算的卫星位置是否连续
% 结果是不连续,运行结束后按行查看zai和ele变量.
% 程序参考GPS.visibility.
% 所以使用星历或历书计算卫星位置时,时间点与参考时刻的正负差不应超过3.5天.
% 如果要计算长时间的,需将周数考虑进去.

% 获取历书
t = UTC2GPS([2020,2,23,15,0,0], 8);
filename = GPS.almanac.download('~temp\almanac', t);
almanac = GPS.almanac.read(filename); %该历书的参考时间为61440
ts = 61440 + 302400 - 1800; %实现ts-toe穿过302400
p = [42.27452, 123.85232, 105]; %接收机位置
h = 1; %持续时间1h

% 使用历书计算所有卫星方位角高度角
svN = size(almanac,1); %卫星数
n = h*30; %点数
azi = zeros(svN,n); %每一列为一个时间点
ele = zeros(svN,n);
for k=1:n
    rs = rs_almanac(almanac(:,5:end), t);
    [azi(:,k), ele(:,k)] = aziele_xyz(rs, p);
    ts = ts+120; %更新时间
end