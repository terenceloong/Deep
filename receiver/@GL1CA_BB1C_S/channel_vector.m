function channel_vector(obj)
% 通道切换矢量跟踪环路

%% GPS部分
if obj.GPSflag==1
    if obj.vectorMode==1
        for k=1:obj.GPS.chN
            channel = obj.GPS.channels(k);
            if channel.state==2
                channel.state = 3;
                channel.codeMode = 2; %码开环
                channel.discBuffPtr = 0; %清鉴相器输出缓存
            end
        end
    elseif obj.vectorMode==2
        for k=1:obj.GPS.chN
            channel = obj.GPS.channels(k);
            if channel.state==2
                channel.state = 3;
                channel.codeMode = 2; %码开环
                channel.carrMode = 3; %矢量二阶锁相环
                channel.discBuffPtr = 0; %清鉴相器输出缓存
            end
        end
    end
end

%% BDS部分
if obj.BDSflag==1
    if obj.vectorMode==1
        for k=1:obj.BDS.chN
            channel = obj.BDS.channels(k);
            if channel.state==2
                channel.state = 3;
                channel.codeMode = 2; %码开环
                channel.discBuffPtr = 0; %清鉴相器输出缓存
            end
        end
	elseif obj.vectorMode==2
        for k=1:obj.BDS.chN
            channel = obj.BDS.channels(k);
            if channel.state==2
                channel.state = 3;
                channel.codeMode = 2; %码开环
                channel.carrMode = 3; %矢量二阶锁相环
                channel.discBuffPtr = 0; %清鉴相器输出缓存
            end
        end
    end
end

end