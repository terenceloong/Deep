function plot_all_trackResult(obj)
% 显示所有通道跟踪结果

if obj.GPSflag==1
    for k=1:obj.GPS.chN
        channel = obj.GPS.channels(k);
        if channel.ns>0 %只画有跟踪数据的通道
            channel.plot_trackResult;
        end
    end
end

if obj.BDSflag==1
    for k=1:obj.BDS.chN
        channel = obj.BDS.channels(k);
        if channel.ns>0 %只画有跟踪数据的通道
            channel.plot_trackResult;
        end
    end
end

end