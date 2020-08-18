function plot_all_carrNco(obj)
% 画所有通道载波驱动频率

for k=1:obj.chN
    channel = obj.channels(k);
    if channel.ns>0 %只画有跟踪数据的通道
        channel.plot_carrNco;
    end
end

end