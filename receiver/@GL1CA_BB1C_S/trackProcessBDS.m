function trackProcessBDS(obj)
% BDS跟踪过程

for k=1:obj.BDS.chN
    channel = obj.BDS.channels(k);
    if channel.state==0 %如果通道未激活,跳过跟踪
        continue
    end
    while 1
        %----判断是否有完整的跟踪数据
        if mod(obj.buffHead-channel.trackDataHead,obj.buffSize)>(obj.buffSize/2)
            break
        end
        %----信号处理
        n1 = channel.trackDataTail;
        n2 = channel.trackDataHead;
        if n2>n1
            channel.track(obj.buffI(n1:n2), obj.buffQ(n1:n2), obj.deltaFreq);
        else
            channel.track([obj.buffI(n1:end),obj.buffI(1:n2)], ...
                          [obj.buffQ(n1:end),obj.buffQ(1:n2)], obj.deltaFreq);
        end
        %----解析导航电文
        channel.parse;
    end
end

end