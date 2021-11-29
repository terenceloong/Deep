function trackProcess(obj)
% 跟踪过程

for m=1:obj.anN
    for k=1:obj.chN
        channel = obj.channels(k,m);
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
                channel.track(obj.buffI{m}(n1:n2), obj.buffQ{m}(n1:n2));
            else
                channel.track([obj.buffI{m}(n1:end),obj.buffI{m}(1:n2)], [obj.buffQ{m}(n1:end),obj.buffQ{m}(1:n2)]);
            end
            %----解析导航电文
            ionoflag = channel.parse;
            %----提取电离层校正参数
            if ionoflag==1
                obj.iono = channel.iono;
            end
        end
    end
end

end