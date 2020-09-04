function plot_all_I_P(obj)
% 画所有通道I_P图

if obj.GPSflag==1
    for k=1:obj.GPS.chN
        channel = obj.GPS.channels(k);
        if channel.ns>0 %只画有跟踪数据的通道
            channel.plot_I_P;
        end
    end
end

if obj.BDSflag==1
    for k=1:obj.BDS.chN
        channel = obj.BDS.channels(k);
        if channel.ns>0 %只画有跟踪数据的通道
            channel.plot_I_P;
        end
    end
end

end