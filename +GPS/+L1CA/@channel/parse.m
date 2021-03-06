function ionoflag = parse(obj)
% 解析导航电文,每1ms执行一次
% 从捕获到进入比特同步要500ms(200ms锁频,300ms锁相环稳定)
% 比特同步过程要2s(100bits),开始寻找帧头要多一点时间,因为等待比特边界到达
% 比特同步后开始寻找帧头,接收一个完整子帧才能校验帧头,至少6s,最多12s
% 验证帧头后就可以确定码发射时间
% 6s一个子帧,30s解析星历一次
% 比特同步后可以增加积分时间
% 增加积分时间需要在刚跟踪完一个比特时做

ionoflag = 0; %如果当前解析的星历帧有电离层参数,该标志位置1

switch obj.msgStage %I,B,W,H,C,E
    case 'I' %空闲
        waitPLLstable;
    case 'B' %比特同步
        bitSync;
    case 'W' %等待比特开始
        waitBitStart;
    otherwise %已经完成比特同步
        if obj.trackCnt==0 %跟踪完一个比特
            bit = ((sum(obj.IpBuff)>0) - 0.5) * 2; %一个比特,±1
            obj.frameBuffPtr = obj.frameBuffPtr + 1; %帧缓存指针加1
            obj.frameBuff(obj.frameBuffPtr) = bit; %往比特缓存里存
            switch obj.msgStage %以下都在处理frameBuff中的内容
                case 'H' %寻找帧头
                    findFrameHead;
                case 'C' %校验帧头
                    checkFrameHead;
                case 'E' %解析星历
                    parseEphemeris;
            end
        end
end

    %% 等待锁相环稳定
    function waitPLLstable
        if obj.carrMode~=2 && obj.carrMode~=4 %非锁相环模式跳过
            obj.trackCnt = 0;
            return
        end
        if obj.trackCnt==300 %到时间了就认为已经稳定
            obj.trackCnt = 0; %计数器清零
            obj.msgStage = 'B'; %进入比特同步阶段
            log_str = sprintf('Start bit synchronization at %.8fs', obj.dataIndex/obj.sampleFreq);
            obj.log = [obj.log; string(log_str)];
        end
    end

    %% 比特同步
    function bitSync
        if obj.I0*obj.I_Q(1)<0 %发现电平翻转
            index = mod(obj.trackCnt-1,20) + 1;
            obj.bitSyncTable(index) = obj.bitSyncTable(index) + 1; %统计表中的对应位加1
        end
        if obj.trackCnt==2000 %2s后检验统计表,此时有100个比特
            if max(obj.bitSyncTable)>10 && (sum(obj.bitSyncTable)-max(obj.bitSyncTable))<=2
                % 比特同步成功,确定电平翻转位置(电平翻转大都发生在一个点上)
                [~,obj.trackCnt] = max(obj.bitSyncTable); %将计数值设为同步表最大值的索引
                obj.bitSyncTable = zeros(1,20); %比特同步统计表清零
                obj.trackCnt = -obj.trackCnt + 1; %如果索引为1,下个积分值就为比特开始处
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
        if obj.trackCnt==0
            obj.bitSyncFlag = 1; %设置比特同步完成标志位
%             obj.set_coherentTime(20); %改变相干积分时间
            obj.msgStage = 'H'; %进入寻找帧头阶段
            log_str = sprintf('Start find head at %.8fs', obj.dataIndex/obj.sampleFreq);
            obj.log = [obj.log; string(log_str)];
        end
    end

    %% 寻找帧头
    function findFrameHead
        if obj.frameBuffPtr>=10 %至少有10个比特,前两个用来校验
            if abs(obj.frameBuff(obj.frameBuffPtr+(-7:0))*[1;-1;-1;-1;1;-1;1;1])==8 %检测到疑似帧头
                obj.frameBuff(1:10) = obj.frameBuff(obj.frameBuffPtr+(-9:0)); %将帧头提前
                obj.frameBuffPtr = 10;
                obj.msgStage = 'C'; %进入校验帧头阶段
            end
            if obj.frameBuffPtr==1502
                obj.frameBuffPtr = 0;
            end
        end
    end

    %% 校验帧头
    function checkFrameHead
        if obj.frameBuffPtr==310 %存储了一个子帧,2+300+8
            if GPS.L1CA.wordCheck(obj.frameBuff(1:32))==1 && ...
               GPS.L1CA.wordCheck(obj.frameBuff(31:62))==1 && ...
               abs(obj.frameBuff(303:310)*[1;-1;-1;-1;1;-1;1;1])==8 %校验通过
                % 获取电文时间
                % frameBuff(32)为上一字的最后一位,校验时控制电平翻转,1表示翻转,参见ICD-GPS最后几页
                bits = -obj.frameBuff(32) * obj.frameBuff(33:49); %电平翻转,31~47比特
                bits = dec2bin(bits>0)'; %±1数组转化为01字符串
                TOW = bin2dec(bits); %01字符串转换为十进制数
                obj.tc0 = (TOW*6+0.16)*1000; %设置伪码周期开始时间,ms,0.16=8/50,已经跟了8个比特
                % TOW为下一子帧开始时间,参见<北斗/GPS双模软件接收机原理与实现技术>96页
                if ~isnan(obj.ephe(1)) %如果已有星历,直接更新通道状态
                    obj.state = 2;
                end
                obj.msgStage = 'E'; %进入解析星历阶段
                log_str = sprintf('Start parse ephemeris at %.8fs', obj.dataIndex/obj.sampleFreq);
                obj.log = [obj.log; string(log_str)];
            else %校验未通过
                for k=11:310 %检查其他比特中有没有帧头
                    if abs(obj.frameBuff(k+(-7:0))*[1;-1;-1;-1;1;-1;1;1])==8 %检测到疑似帧头
                        obj.frameBuff(1:320-k) = obj.frameBuff(k-9:310); %将帧头后面的比特提前,320-k=310-(k-9)+1
                        obj.frameBuffPtr = 320-k; %表示帧缓存中有多少个数
                        break
                    end
                end
                if obj.frameBuffPtr==310 %没检测到疑似帧头
                    obj.frameBuff(1:9) = obj.frameBuff(302:310); %将未检测的比特提前
                    obj.frameBuffPtr = 9;
                    obj.msgStage = 'H'; %再次寻找帧头
                end
            end
        end
    end

    %% 解析星历
    function parseEphemeris
        if obj.frameBuffPtr==1502 %跟踪完5帧
            % 检查第一帧的子帧ID,不能是子帧3(如果是子帧3,星历不是一起发的)
            bits = -obj.frameBuff(32) * obj.frameBuff(52:54); %电平翻转,50~52比特
            bits = dec2bin(bits>0)'; %±1数组转化为01字符串
            subframeID = bin2dec(bits); %01字符串转换为十进制数
            if subframeID==3
                obj.frameBuff(1:1202) = obj.frameBuff(301:1502); %将后四帧提前
                obj.frameBuffPtr = 1202;
                return
            end
            %---------------------------------------------------------
            [ephe, iono] = GPS.L1CA.epheParse(obj.frameBuff); %解析星历
            if ~isempty(ephe) %星历解析成功
                if ~isempty(iono) %有电离层参数
                    obj.iono = iono; %更新电离层参数
                    ionoflag = 1; %设置电离层参数标志
                end
                if mod(ephe(3),256)==ephe(4) %IODC的低8位==IODE
                    log_str = sprintf('Ephemeris is parsed at %.8fs', obj.dataIndex/obj.sampleFreq);
                    obj.log = [obj.log; string(log_str)];
                    obj.ephe = ephe; %更新星历
                    if obj.state==1
                        obj.state = 2; %改变通道状态
                    end
                else %IODC的低8位~=IODE
                    log_str = sprintf('***Ephemeris changes at %.8fs, IODC=%d, IODE=%d', ...
                                      obj.dataIndex/obj.sampleFreq, ephe(3), ephe(4));
                    obj.log = [obj.log; string(log_str)];
                end
            else %解析星历错误
                log_str = sprintf('***Ephemeris error at %.8fs', obj.dataIndex/obj.sampleFreq);
                obj.log = [obj.log; string(log_str)];
            end
            obj.frameBuff(1:2) = obj.frameBuff(1501:1502); %将最后两个比特提前
            obj.frameBuffPtr = 2;
        end
    end

end