function plot_all_carrAcc(obj)
% 画所有通道载波加速度

if obj.GPSflag==1
    for k=1:obj.GPS.chN
        channel = obj.GPS.channels(k);
        if channel.ns>0 %只画有跟踪数据的通道
            channel.plot_carrAcc;
        end
    end
end

if obj.BDSflag==1
    for k=1:obj.BDS.chN
        channel = obj.BDS.channels(k);
        if channel.ns>0 %只画有跟踪数据的通道
            channel.plot_carrAcc;
        end
    end
end

end