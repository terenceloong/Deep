function plot_all_carrAcc(obj)
% 画所有通道载波加速度

for k=1:obj.chN
    channel = obj.channels(k);
    if channel.ns>0 %只画有跟踪数据的通道
        channel.plot_carrAcc;
    end
end

end