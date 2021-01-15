function channel_deep(obj)
% 通道切换深组合跟踪环路

if obj.deepMode==1
    for k=1:obj.chN
        channel = obj.channels(k);
        if channel.state==2
            channel.state = 3;
            channel.codeMode = 2; %更换码环
            channel.codeDiscBuffPtr = 0; %清码鉴相器输出缓存
        end
    end
elseif obj.deepMode==2
    for k=1:obj.chN
        channel = obj.channels(k);
        if channel.state==2
            channel.state = 3;
            channel.codeMode = 2; %更换码环
            channel.carrMode = 3; %更换载波环
            channel.codeDiscBuffPtr = 0; %清码鉴相器输出缓存
        end
    end
end

end