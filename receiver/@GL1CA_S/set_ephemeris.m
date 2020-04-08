function set_ephemeris(obj, filename)
% 预设星历

% 检查预存星历是否存在,如果不存在就创建一个空的
if ~exist(filename, 'file')
    ephemeris = []; %变量名为ephemeris,是个结构体
    save(filename, 'ephemeris') %保存到文件中
end

% 加载预存的星历
load(filename, 'ephemeris')

% 检查预存星历中是否存在GPS星历,如果不存在,创建空的GPS星历
if ~isfield(ephemeris, 'GPS_ephe')
    ephemeris.GPS_ephe = NaN(32,25); %每行一颗卫星
    ephemeris.GPS_iono = NaN(1,8);
    save(filename, 'ephemeris') %保存到文件中
end

% 提取星历
obj.iono = ephemeris.GPS_iono; %提取电离层校正参数
for k=1:obj.chN %为每个通道赋星历
    channel = obj.channels(k);
    channel.ephe = ephemeris.GPS_ephe(channel.PRN,:);
end

end