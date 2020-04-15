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
        for k=1:obj.chN
            channel = obj.channels(k);
            if channel.state==2
                channel.state = 3;
                channel.codeMode = 2; %更换码环
                channel.carrMode = 3; %更换载波环
                channel.markCurrStorage;
%                 [K1, K2] = order2LoopCoefD(15, 0.707, channel.timeIntS);
%                 channel.PLL2 = [K1, K2];
            end
        end
end

end