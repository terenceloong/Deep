%% 观察GPS广播星历中的群延迟项
% 先读一个RINEX星历文件,赋给变量ephe.
% 大部分是负的,最大-6m.

% 下载一天的星历
filename = GPS.ephemeris.download('~temp\ephemeris', '2020-02-22');
ephe = RINEX.read_N2(filename);

% 提取每颗卫星第一个星历的群延迟
TGD = zeros(32,1);
for k=1:32
    if ~isempty(ephe.sv{k}) %有可能某颗卫星没星历
        TGD(k) = ephe.sv{k}(1).TGD;
    end
end
TGD = TGD*3e8; %单位:m

% 画直方图
figure
bar(TGD)