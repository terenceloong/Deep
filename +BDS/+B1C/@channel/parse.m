function parse(obj)
% 解析导航电文
% 从捕获到进入比特同步要300ms(等待锁相环稳定)
% 比特同步过程要1s(100bits),开始寻找帧头要多一点时间,因为等待比特边界到达
% 比特同步后使用导频子码进行帧同步
% 帧同步过程要500ms(50bits),等到下一帧开始才进入星历解析
% 帧同步后就确定了导频子码相位,根据需要翻转载波相位,启动纯锁相环
% 一帧星历接收完后才能确定码发射时间
% 星历18s一次

obj.msgCnt = obj.msgCnt + 1; %计数加1

switch obj.msgStage %I,B,W,F,H,E
    case 'I' %空闲
        waitPLLstable;
    case 'B' %比特同步
        bitSync;
	case 'W' %等待比特开始
        waitBitStart;
    otherwise %已经完成比特同步
        if obj.msgCnt==1 %记录比特开始标志
            obj.storage.bitFlag(obj.ns) = obj.msgStage;
        end
        obj.SQI.run(obj.I, obj.Q); %评估信号质量
        obj.quality = obj.SQI.quality;
        obj.storage.quality(obj.ns) = obj.quality;
        %------------------------------------------
        switch obj.msgStage
            case 'F' %帧同步
                frameSync;
            case 'H' %等待帧头
                waitFrameHead;
            case 'E' %解析星历
                parseEphemeris;
        end
end

    %% 等待锁相环稳定
    function waitPLLstable
        if obj.msgCnt==300 %到时间了就认为已经稳定
            obj.msgCnt = 0; %计数器清零
            obj.msgStage = 'B'; %进入比特同步阶段
            log_str = sprintf('Start bit synchronization at %.8fs', obj.dataIndex/obj.sampleFreq);
            obj.log = [obj.log; string(log_str)];
        end
    end

    %% 比特同步
    function bitSync
        if obj.Ip0*obj.Ip<0 %发现电平翻转
            index = mod(obj.msgCnt-1,10) + 1;
            obj.bitSyncTable(index) = obj.bitSyncTable(index) + 1; %统计表中的对应位加1
        end
        obj.Ip0 = obj.Ip;
        if obj.msgCnt==1000 %1s后检验统计表,此时有100个比特
            obj.Ip0 = 0; %Ip0后来就不用了,给它复位
            if max(obj.bitSyncTable)>10 && (sum(obj.bitSyncTable)-max(obj.bitSyncTable))<=2
                % 比特同步成功,确定电平翻转位置(电平翻转大都发生在一个点上)
                [~,obj.msgCnt] = max(obj.bitSyncTable); %将计数值设为同步表最大值的索引
                obj.bitSyncTable = zeros(1,10); %比特同步统计表清零
                obj.msgCnt = -obj.msgCnt + 1; %如果索引为1,下个积分值就为比特开始处
                obj.msgStage = 'W'; %等待比特开始
                waitBitStart;
            else
                % 比特同步失败,关闭通道
                obj.state = 0;
                obj.ns = obj.ns + 1; %数据存储跳一个,相当于加一个间断点
                log_str = sprintf('***Bit synchronization failed at %.8fs', obj.dataIndex/obj.sampleFreq);
                obj.log = [obj.log; string(log_str)];
            end
        end
    end

    %% 等待比特开始
    function waitBitStart
        if obj.msgCnt==0
            obj.msgStage = 'F'; %进入帧同步阶段
            log_str = sprintf('Start frame synchronization at %.8fs', obj.dataIndex/obj.sampleFreq);
            obj.log = [obj.log; string(log_str)];
        end
    end

    %% 帧同步
    function frameSync
        obj.bitBuff(obj.msgCnt) = obj.Ip; %往比特缓存中存数,导频子码
        if obj.msgCnt==obj.pointInt %跟踪完一个比特
            obj.msgCnt = 0; %计数器清零
            obj.frameBuffPtr = obj.frameBuffPtr + 1; %帧缓存指针加1
            bit = (double(sum(obj.bitBuff(1:obj.pointInt))>0) - 0.5) * 2; %一个比特,±1
            obj.frameBuff(obj.frameBuffPtr) = bit; %往比特缓存里存
            % 采集一段时间导频子码,确定其在子码序列中的位置
            if obj.frameBuffPtr==50 %存了50个比特
                R = zeros(1,1800); %50个比特在子码序列不同位置的相关结果
                code = [obj.codeSub, obj.codeSub(1:49)];
                x = obj.frameBuff(1:50)'; %列向量
                for k=1:1800
                    R(k) = code(k:k+49) * x;
                end
                [Rmax, index] = max(abs(R)); %寻找相关结果的最大值
                if Rmax==50 %最大相关值正确
                    %----启动纯锁相环----
                    if R(index)<0
                        obj.remCarrPhase = mod(obj.remCarrPhase+0.5, 1); %翻转载波相位
                    end
                    obj.subPhase = mod(index+49,1800) + 1; %确定导频子码相位
                    obj.carrDiscFlag = 1; %使用四象限载波鉴相器
                    %-------------------
                    obj.frameBuffPtr = mod(index+49,1800); %帧缓存指针移动
                    if obj.frameBuffPtr==0
                        obj.msgStage = 'E'; %进入解析星历阶段
                        log_str = sprintf('Start parse ephemeris at %.8fs', obj.dataIndex/obj.sampleFreq);
                        obj.log = [obj.log; string(log_str)];
                    else
                        obj.msgStage = 'H'; %等待帧头
                    end
                else %最大相关值错误
                    obj.frameBuffPtr = 0; %帧缓存指针归位
                    obj.msgStage = 'B'; %返回比特同步阶段(如果还留在帧同步阶段会出不去)
                    log_str = sprintf('***Frame synchronization failed at %.8fs', obj.dataIndex/obj.sampleFreq);
                    obj.log = [obj.log; string(log_str)];
                end
            end
        end
    end

    %% 等待帧头
    function waitFrameHead %此时不用存数,等下一帧来
        if obj.msgCnt==obj.pointInt %跟踪完一个比特
            obj.msgCnt = 0; %计数器清零
            obj.frameBuffPtr = obj.frameBuffPtr + 1; %帧缓存指针加1
            if obj.frameBuffPtr==1800
                obj.frameBuffPtr = 0; %帧缓存指针归位
                obj.msgStage = 'E'; %进入解析星历阶段
                log_str = sprintf('Start parse ephemeris at %.8fs', obj.dataIndex/obj.sampleFreq);
                obj.log = [obj.log; string(log_str)];
            end
        end
    end

    %% 解析星历
    function parseEphemeris
        obj.bitBuff(obj.msgCnt) = obj.Id; %往比特缓存中存数,导航电文
        if obj.msgCnt==obj.pointInt %跟踪完一个比特
            obj.msgCnt = 0; %计数器清零
            obj.frameBuffPtr = obj.frameBuffPtr + 1; %帧缓存指针加1
            bit = (double(sum(obj.bitBuff(1:obj.pointInt))>0) - 0.5) * 2; %一个比特,±1
            obj.frameBuff(obj.frameBuffPtr) = bit; %往比特缓存里存
            if obj.frameBuffPtr==1800 %存了1800个比特(一帧)
                obj.frameBuffPtr = 0; %帧缓存指针归位
                [~, SOH, ephe, sf3] = BDS.B1C.epheParse(obj.frameBuff);
                if ~isempty(ephe) %解析星历成功
                    obj.tc0 = (ephe(2)*3600 + SOH + 18) * 1000; %设置伪码时间
                    if mod(ephe(3),256)==ephe(4) %IODC的低8位==IODE
                        log_str = sprintf('Ephemeris is parsed at %.8fs', obj.dataIndex/obj.sampleFreq);
                        obj.log = [obj.log; string(log_str)];
                        obj.ephe = ephe; %更新星历
                        obj.state = 2; %改变通道状态
                    else %IODC的低8位~=IODE
                        log_str = sprintf('***Ephemeris changes at %.8fs, IODC=%d, IODE=%d', ...
                                           obj.dataIndex/obj.sampleFreq, ephe(3), ephe(4));
                        obj.log = [obj.log; string(log_str)];
                    end
                else %解析星历错误
                    log_str = sprintf('***Ephemeris error at %.8fs', obj.dataIndex/obj.sampleFreq);
                    obj.log = [obj.log; string(log_str)];
                end
            end
        end
    end

end