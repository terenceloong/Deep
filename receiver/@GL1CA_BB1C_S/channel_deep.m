function channel_deep(obj)
% 通道切换深组合跟踪环路

%% GPS部分
if obj.GPSflag==1
    if obj.deepMode==1
        for k=1:obj.GPS.chN
            channel = obj.GPS.channels(k);
            if channel.state==2
                channel.state = 3;
                channel.codeMode = 2; %更换码环
                channel.markCurrStorage;
            end
        end
    elseif obj.deepMode==2
        for k=1:obj.GPS.chN
            channel = obj.GPS.channels(k);
            if channel.state==2
                channel.state = 3;
                channel.codeMode = 2; %更换码环
                channel.carrMode = 3; %更换载波环
                channel.markCurrStorage;
            end
        end
    end
end

%% BDS部分
if obj.BDSflag==1
    if obj.deepMode==1
        for k=1:obj.BDS.chN
            channel = obj.BDS.channels(k);
            if channel.state==2
                channel.state = 3;
                channel.codeMode = 2; %更换码环
                channel.markCurrStorage;
            end
        end
	elseif obj.deepMode==2
        for k=1:obj.BDS.chN
            channel = obj.BDS.channels(k);
            if channel.state==2
                channel.state = 3;
                channel.codeMode = 2; %更换码环
                channel.carrMode = 3; %更换载波环
                channel.markCurrStorage;
            end
        end
    end
end

end