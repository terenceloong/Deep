function acqProcess(obj)
% 捕获过程

for m=1:obj.anN
    for k=1:obj.chN
        channel = obj.channels(k,m);
        if channel.state~=0 %如果通道已激活,跳过捕获
            continue
        end
        n = channel.acqN; %捕获采样点数
        acqResult = channel.acq(obj.buffI{m}((end-2*n+1):end), obj.buffQ{m}((end-2*n+1):end));
        if ~isempty(acqResult) %捕获成功后初始化通道
            channel.init(acqResult, obj.tms/1000*obj.sampleFreq);
        end
    end
end

end