function run(obj, data)
% 接收机运行函数
% data:采样数据,两行,分别为I/Q数据,原始数据类型
% 使用嵌套函数写,提高程序可读性,要保证只有obj是全局变量

% 往数据缓存存数
obj.buffI(:,obj.blockPoint) = data(1,:); %往数据缓存的指定块存数,不用加转置,自动变成列向量
obj.buffQ(:,obj.blockPoint) = data(2,:);
obj.buffHead = obj.blockPoint * obj.blockSize; %最新数据的位置
obj.blockPoint = obj.blockPoint + 1; %指向下一块
if obj.blockPoint>obj.blockNum
    obj.blockPoint = 1;
end
obj.tms = obj.tms + 1; %当前运行时间加1ms

% 更新接收机时间
fs = obj.sampleFreq * (1+obj.deltaFreq); %修正后的采样频率
obj.ta = timeCarry(obj.ta + sample2dt(obj.blockSize, fs));

% 捕获
if mod(obj.tms,1000)==0 %1s搜索一次
    acqProcess;
end

% 跟踪
trackProcess;

% 定位
dtp = (obj.ta-obj.tp) * [1;1e-3;1e-6]; %当前接收机时间与定位时间之差,s
if dtp>=0 %定位时间到了
    %----获取卫星测量信息
    satmeas = get_satmeas(dtp, fs);
    %----选星
    sv = satmeas(~isnan(satmeas(:,1)),:); %选有数据的行
    %----卫星导航解算
    satnav = satnavSolve(sv, obj.rp);
    dtr = satnav(13); %接收机钟差,s
    dtv = satnav(14); %接收机钟频差,s/s
    %----更新接收机位置速度
    if ~isnan(satnav(1))
        obj.pos = satnav(1:3);
        obj.rp  = satnav(4:6);
        obj.vel = satnav(7:9);
        obj.vp  = satnav(10:12);
    end
    %----接收机时钟修正
    if obj.state==1 && ~isnan(dtv)
        
    end
    %----数据存储
    obj.ns = obj.ns+1; %指向当前存储行
    m = obj.ns;
    obj.storage.ta(m) = obj.tp * [1;1e-3;1e-6]; %定位时间,s
    obj.storage.state(m) = obj.state;
    obj.storage.df(m) = obj.deltaFreq;
    obj.storage.satmeas(:,:,m) = satmeas;
    obj.storage.satnav(m,:) = satnav([1,2,3,7,8,9,13,14]);
    obj.storage.pos(m,:) = obj.pos;
    obj.storage.vel(m,:) = obj.vel;
    %----接收机时钟初始化
    if obj.state==0 && ~isnan(dtr)
        clock_init(dtr);
    end
    %----更新下次定位时间
    obj.tp = timeCarry(obj.tp + [0,obj.dtpos,0]);
end

    %% 捕获过程
    function acqProcess
        for k=1:obj.chN
            if obj.channels(k).state~=0 %如果通道已激活,跳过捕获
                continue
            end
            n = obj.channels(k).acqN; %捕获采样点数
            acqResult = obj.channels(k).acq(obj.buffI((end-2*n+1):end), obj.buffQ((end-2*n+1):end));
            if ~isempty(acqResult) %捕获成功后初始化通道
                obj.channels(k).init(acqResult, obj.tms/1000*obj.sampleFreq);
            end
        end
    end

    %% 跟踪过程
    function trackProcess
        for k=1:obj.chN
            if obj.channels(k).state==0 %如果通道未激活,跳过跟踪
                continue
            end
            while 1
                %----判断是否有完整的跟踪数据
                if mod(obj.buffHead-obj.channels(k).trackDataHead,obj.buffSize)>(obj.buffSize/2)
                    break
                end
                %----信号处理
                n1 = obj.channels(k).trackDataTail;
                n2 = obj.channels(k).trackDataHead;
                if n2>n1
                    obj.channels(k).track(obj.buffI(n1:n2), obj.buffQ(n1:n2), obj.deltaFreq);
                else
                    obj.channels(k).track([obj.buffI(n1:end),obj.buffI(1:n2)], ...
                                          [obj.buffQ(n1:end),obj.buffQ(1:n2)], obj.deltaFreq);
                end
                %----解析导航电文
                ionoflag = obj.channels(k).parse;
                %----提取电离层校正参数
                if ionoflag==1
                    obj.iono = obj.channels(k).iono;
                end
            end
        end
    end

    %% 获取卫星测量
    function satmeas = get_satmeas(dtp, fs)
        % dtp:当前采样点到定位点的时间差,s,dtp=ta-tp
        % fs:接收机钟频差校正后的采样频率,Hz
        % satmeas:[x,y,z,vx,vy,vz,rho,rhodot]
        lamda = 0.190293672798365; %载波波长,m,299792458/1575.42e6
        satmeas = NaN(obj.chN,8);
        for k=1:obj.chN
            if obj.channels(k).state==2 %只要跟踪上的通道都能测,这里不用管信号质量,选星额外来做
                %----计算定位点所接到码的发射时间
                dn = mod(obj.buffHead-obj.channels(k).trackDataTail+1, obj.buffSize) - 1; %恰好超前一个采样点时dn=-1
                dtc = dn / fs; %当前采样点到跟踪点的时间差,dtc=ta-tc
                dt = dtc - dtp; %定位点到跟踪点的时间差,dtc-dtp=(ta-tc)-(ta-tp)=tp-tc=dt
                codePhase = obj.channels(k).remCodePhase + obj.channels(k).codeNco*dt; %定位点码相位
                te = [floor(obj.channels(k).tc0/1e3), mod(obj.channels(k).tc0,1e3), 0] + ...
                      [0, floor(codePhase/1023), mod(codePhase/1023,1)*1e3]; %定位点码发射时间
                %----计算信号发射时刻卫星位置速度
                % [satmeas(k,1:6), corr] =LNAV.rsvs_emit(obj.channels(k).ephe(5:end), te, obj.rp, obj.iono, obj.pos);
                %----计算信号发射时刻卫星位置速度加速度
                [rsvsas, corr] =LNAV.rsvsas_emit(obj.channels(k).ephe(5:end), te, obj.rp, obj.iono, obj.pos);
                satmeas(k,1:6) = rsvsas(1:6);
                %----计算卫星运动引起的载波频率变化率(短时间近似不变,使用上一时刻的位置计算就行,视线矢量差别不大)
                rs = rsvsas(1:3); %卫星位置矢量
                vs = rsvsas(4:6); %卫星速度矢量
                as = rsvsas(7:9); %卫星加速度矢量
                rps = rs - obj.rp; %接收机指向卫星位置矢量
                R = norm(rps); %接收机到卫星的距离
                carrAcc = -(as*rps'+vs*vs'-(vs*rps'/R)^2)/R / lamda; %载波频率变化率,Hz/s
                obj.channels(k).set_carrAcc(carrAcc); %设置跟踪通道载波频率变化率
                %----计算伪距伪距率
                tt = (obj.tp-te) * [1;1e-3;1e-6]; %信号传播时间,s
                doppler = obj.channels(k).carrFreq/1575.42e6 + obj.deltaFreq; %归一化,接收机钟快使多普勒变小(发生在下变频)
                satmeas(k,7:8) = satmeasCorr(tt, doppler, corr);
            end
        end
    end

    %% 接收机时钟初始化
    function clock_init(dtr)
        % dtr:卫星导航解算得到的接收机钟差,s
        if abs(dtr)>0.1e-3 %钟差大于0.1ms,修正接收机时间
            obj.ta = obj.ta - sec2smu(dtr);
            obj.ta = timeCarry(obj.ta);
            obj.tp(1) = obj.ta(1); %更新下次定位时间
            obj.tp(2) = ceil(obj.ta(2)/obj.dtpos) * obj.dtpos;
            obj.tp = timeCarry(obj.tp);
        else %钟差小于0.1ms,初始化结束
            obj.state = 1;
        end
    end

end