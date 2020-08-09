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

% 更新接收机时间
dta = sample2dt(obj.blockSize, obj.sampleFreq*(1+obj.deltaFreq)); %时间增量
obj.ta = timeCarry(obj.ta + dta);

% GPS信号捕获跟踪
if obj.GPSflag==1
    % 捕获
    if obj.tms==obj.blockNum || mod(obj.tms,2000)==0 %2s搜索一次
        obj.acqProcessGPS;
    end
    % 跟踪
    obj.trackProcessGPS;
end

% 北斗信号捕获跟踪
if obj.BDSflag==1
    % 捕获
    if obj.tms==obj.blockNum %|| mod(obj.tms,10000)==0 %10s搜索一次
        obj.acqProcessBDS;
    end
    % 跟踪
    obj.trackProcessBDS;
end

% 定位
if (obj.ta-obj.tp)*[1;1e-3;1e-6]>=0 %定位时间到了
    switch obj.state
        case 0 %初始化
            obj.pos_init;
        case 1 %正常
            obj.pos_normal;
%         case 2 %紧组合
%             obj.pos_tight;
        case 3 %深组合
            obj.pos_deep;
    end
end

end