% 提取GPS广播星历中的群延迟项
% 先读一个RINEX星历文件,赋给变量ephe

TGD = zeros(32,1);

for k=1:32
    if ~isempty(ephe.sv{k}) %有可能某颗卫星没星历
        TGD(k) = ephe.sv{k}(1).TGD;
    end
end

TGD = TGD*3e8; %单位:m
figure
bar(TGD)