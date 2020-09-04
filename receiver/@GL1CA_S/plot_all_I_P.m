function plot_all_I_P(obj)
% 画所有通道I_P图

for k=1:obj.chN
    channel = obj.channels(k);
    if channel.ns>0 %只画有跟踪数据的通道
        channel.plot_I_P;
    end
end

end