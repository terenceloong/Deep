function channel_deep(obj)
% 通道切换深组合跟踪环路

switch obj.deepMode
    case 1
        for k=1:obj.chN
            channel = obj.channels(k);
            if channel.state==2
                channel.state = 3;
                channel.codeMode = 2; %更换码环
                channel.markCurrStorage;
            end
        end
    case 2
        
end

end