function channel_vector(obj)
% 通道切换矢量跟踪环路

if obj.vectorMode==1 %只有码环矢量跟踪
    for k=1:obj.chN
        channel = obj.channels(k);
        if channel.state==2
            channel.state = 3;
            channel.codeMode = 2; %码开环
            channel.codeDiscBuffPtr = 0; %清码鉴相器输出缓存
        end
    end
elseif obj.vectorMode==2 %码环和载波环都做矢量跟踪,载波环二阶
    for k=1:obj.chN
        channel = obj.channels(k);
        if channel.state==2
            channel.state = 3;
            channel.codeMode = 2; %码开环
            channel.carrMode = 3; %矢量二阶锁相环
            channel.codeDiscBuffPtr = 0; %清码鉴相器输出缓存
        end
    end
elseif obj.vectorMode==3 %码环和载波环都做矢量跟踪,载波环三阶
    for k=1:obj.chN
        channel = obj.channels(k);
        if channel.state==2
            channel.state = 3;
            channel.codeMode = 2; %码开环
            channel.carrMode = 5; %矢量三阶锁相环
            channel.codeDiscBuffPtr = 0; %清码鉴相器输出缓存
        end
    end
end

end