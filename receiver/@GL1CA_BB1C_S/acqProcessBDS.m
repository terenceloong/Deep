function acqProcessBDS(obj)
% BDS捕获过程

for k=1:obj.BDS.chN
    channel = obj.BDS.channels(k);
    if channel.state~=0 %如果通道已激活,跳过捕获
        continue
    end
    n = channel.acqN; %捕获采样点数
    acqResult = channel.acq(obj.buffI((end-n+1):end), obj.buffQ((end-n+1):end));
    if ~isempty(acqResult) %捕获成功后初始化通道
        channel.init(acqResult, obj.tms/1000*obj.sampleFreq);
    end
end

end