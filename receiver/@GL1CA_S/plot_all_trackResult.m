function plot_all_trackResult(obj)
% 显示所有通道跟踪结果

for k=1:obj.chN
    channel = obj.channels(k);
    if channel.ns>0 %只画有跟踪数据的通道
        channel.plot_trackResult;
    end
end

end