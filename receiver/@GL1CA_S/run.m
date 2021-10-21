function run(obj, data)
% 接收机运行函数
% data:采样数据,两行,分别为I/Q数据,原始数据类型

% 往数据缓存存数
obj.buffI(:,obj.blockPtr) = data(1,:); %往数据缓存的指定块存数,不用加转置,自动变成列向量
obj.buffQ(:,obj.blockPtr) = data(2,:);
obj.buffHead = obj.blockPtr * obj.blockSize; %最新数据的位置
obj.blockPtr = obj.blockPtr + 1; %指向下一块
if obj.blockPtr>obj.blockNum
    obj.blockPtr = 1;
end
obj.tms = obj.tms + 1; %当前运行时间加1ms

% 钟频差系数
Cdf = 1 + obj.deltaFreq;
Ddf = obj.deltaFreq / Cdf;

% 更新接收机时间
dta = sample2dt(obj.blockSize, obj.sampleFreq*Cdf); %时间增量
obj.ta = timeCarry(obj.ta + dta);
obj.clockError = obj.clockError + obj.blockTime*Ddf; %累计钟差修正量(接收机钟减,累计值加)
% 如果df等于0,接收机钟应该走T;当df不为0时,接收机钟走了T/(1+df),相当于接收机钟减了T*df/(1+df)

% 捕获
if mod(obj.tms,1000)==0 %1s搜索一次
    obj.acqProcess;
end

% 跟踪
obj.trackProcess;

% 定位
if (obj.ta-obj.tp)*[1;1e-3;1e-6]>=0 %定位时间到了
    switch obj.state
        case 0 %初始化
            obj.pos_init;
        case 1 %正常
            obj.pos_normal;
        case 2 %紧组合
            obj.pos_tight;
        case 3 %深组合
            obj.pos_deep;
        case 4 %纯矢量跟踪
            obj.pos_vector;
    end
end

end