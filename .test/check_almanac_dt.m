% 观察当时间按周内秒数取模时计算的卫星位置是否连续
% 结果是不连续,运行结束后按行查看zai和ele变量
% 程序参考GPS.visibility
% 所以使用星历或历书计算卫星位置时,时间点与参考时刻的正负差不应超过3.5天
% 如果要计算长时间的,需将周数考虑进去

filename = GPS.almanac.download('~temp\almanac', UTC2GPS([2020,2,23,15,0,0],8));
almanac = GPS.almanac.read(filename); %历书参考时间61440
ts = 61440 + 302400 - 1800; %实现ts-toe穿过302400
p = [42.27452,123.85232,105]; %接收机位置
h = 1; %持续时间1h

% 使用历书计算所有卫星方位角高度角
n = size(almanac,1); %卫星数
m = h*30; %点数
aziele = zeros(n,2,m); %[azi,ele],第三维为时间
for k=1:m
    aziele(:,:,k) = aziele_almanac(almanac(:,6:end), ts, p); %[azi,ele]
    ts = ts+120; %更新时间
end

% 获取高度角大于0的卫星
index = zeros(1,n, 'logical'); %可见卫星索引
for k=1:n
    if ~isempty(find(aziele(k,2,:)>0,1)) %存在高度角大于0
        index(k) = 1;
    end
end
PRN = almanac(index,1);
azi = mod(aziele(index,1,:),360)/180*pi; %方位角转成弧度,0~360度
azi = reshape(azi,length(PRN),m); %行为卫星,列为时间
ele = aziele(index,2,:);
ele = reshape(ele,length(PRN),m);