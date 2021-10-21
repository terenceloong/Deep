function satmeas = get_satmeasGPS(obj)
% 获取GPS卫星测量

Fca = 1575.42e6; %载波频率
Lca = 0.190293672798365; %载波波长,m

SMU2S = [1;1e-3;1e-6]; %[s,ms,us]到s
Cdf = 1 + obj.deltaFreq; %跟踪频率到真实频率的系数
Ddf = obj.deltaFreq / Cdf; %df/(1+df)
dtp = (obj.ta-obj.tp)*SMU2S * Cdf; %当前采样点到定位点的时间差(接收机钟)

satmeas = NaN(obj.GPS.chN,9);
for k=1:obj.GPS.chN
    channel = obj.GPS.channels(k);
    if channel.state>=2 %只要跟踪上的通道都能测,这里不用管信号质量,选星额外来做
        %----计算定位点所接到码的发射时间
        dn = mod(obj.buffHead-channel.trackDataTail+1, obj.buffSize) - 1; %恰好超前一个采样点时dn=-1
        dtc = dn / obj.sampleFreq; %当前采样点到跟踪点的时间差(接收机钟)
        dt = dtc - dtp; %定位点到跟踪点的时间差(接收机钟)
        codePhase = channel.remCodePhase + channel.codeNco*dt; %定位点码相位
        te = [floor(channel.tc0/1e3), mod(channel.tc0,1e3), 0] + ...
             [0, floor(codePhase/1023), mod(codePhase/1023,1)*1e3]; %定位点码发射时间
        %----计算信号发射时刻卫星位置速度
        % [satmeas(k,1:6), corr] = LNAV.rsvs_emit(channel.ephe(5:end), te, obj.rp, obj.vp, obj.GPS.iono, obj.pos);
        %----计算信号发射时刻卫星位置速度加速度
        [rsvsas, corr] = LNAV.rsvsas_emit(channel.ephe(5:end), te, obj.rp, obj.vp, obj.GPS.iono, obj.pos);
        satmeas(k,1:6) = rsvsas(1:6);
        %----计算卫星运动引起的载波频率变化率(短时间近似不变,使用上一时刻的位置计算就行,视线矢量差别不大)
        rhodotdot = rhodotdot_cal(rsvsas, obj.rp, obj.vp, obj.geogInfo);
        channel.carrAccS = -rhodotdot/Lca / Cdf; %设置跟踪通道载波频率变化率,Hz/s
        %----计算伪距伪距率
        tt = (obj.tp-te) * SMU2S; %信号传播时间,s
        carrAcc = channel.carrAccS + channel.carrAccR;
        dCarrFreq = carrAcc * (dt-0.5e-3);
        doppler = (channel.carrFreq+dCarrFreq)*Cdf/Fca + obj.deltaFreq; %归一化,接收机钟快使多普勒变小(发生在下变频)
        satmeas(k,7:8) = satmeasCorr(tt, doppler, corr);
        %----计算载波相位
        clockError = obj.clockError + dt*Ddf; %到定位点累积了多少钟差
        carrPhase = channel.carrCirc - channel.remCarrPhase - channel.carrNco*dt; %定位点的载波相位(累积负频率)
        carrPhase = carrPhaseCorr(carrPhase, corr, Fca); %载波相位校正
        carrPhase = carrPhase - clockError*Fca; %补偿接收机钟差
        dL = satmeas(k,7) - carrPhase*Lca; %载波相位对应的距离与伪距之差
        if abs(dL)>300 %如果差大于300m,则进行调整,令载波相位与伪距匹配
            dcarrCirc = round(dL/Lca); %载波相位整周修正量
            channel.carrCirc = channel.carrCirc + dcarrCirc; %修载波相位整周计数
            carrPhase = carrPhase + dcarrCirc; %修载波相位
        end
        satmeas(k,9) = carrPhase;
    end
end

end