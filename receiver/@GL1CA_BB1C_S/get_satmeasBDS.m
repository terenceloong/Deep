function satmeas = get_satmeasBDS(obj)
% 获取BDS卫星测量

Fca = 1575.42e6; %载波频率
Lca = 0.190293672798365; %载波波长,m

SMU2S = [1;1e-3;1e-6]; %[s,ms,us]到s
Cdf = 1 + obj.deltaFreq; %跟踪频率到真实频率的系数
dtp = (obj.ta-obj.tp)*SMU2S * Cdf; %当前采样点到定位点的时间差(接收机钟)

satmeas = NaN(obj.BDS.chN,8);
for k=1:obj.BDS.chN
    channel = obj.BDS.channels(k);
    if channel.state>=2 %只要跟踪上的通道都能测,这里不用管信号质量,选星额外来做
        %----计算定位点所接到码的发射时间
        dn = mod(obj.buffHead-channel.trackDataTail+1, obj.buffSize) - 1; %恰好超前一个采样点时dn=-1
        dtc = dn / obj.sampleFreq; %当前采样点到跟踪点的时间差(接收机钟)
        dt = dtc - dtp; %定位点到跟踪点的时间差(接收机钟)
        codePhase = channel.remCodePhase + channel.codeNco*dt; %定位点码相位
        te = [floor(channel.tc0/1e3), mod(channel.tc0,1e3), 0] + ...
             [0, floor(codePhase/2046), mod(codePhase/2046,1)*1e3]; %定位点码发射时间(考虑子载波时码频率2.046e6Hz)
        %----计算信号发射时刻卫星位置速度
        % [satmeas(k,1:6), corr] = CNAV1.rsvs_emit(channel.ephe(5:end), te, obj.rp, obj.vp, obj.BDS.iono, obj.pos);
        %----计算信号发射时刻卫星位置速度加速度
        [rsvsas, corr] = CNAV1.rsvsas_emit(channel.ephe(5:end), te, obj.rp, obj.vp, obj.BDS.iono, obj.pos);
        satmeas(k,1:6) = rsvsas(1:6);
        %----计算卫星运动引起的载波频率变化率(短时间近似不变,使用上一时刻的位置计算就行,视线矢量差别不大)
        rhodotdot = rhodotdot_cal(rsvsas, obj.rp, obj.vp, obj.geogInfo);
        channel.carrAccS = -rhodotdot/Lca / Cdf; %设置跟踪通道载波频率变化率,Hz/s
        %----计算伪距伪距率
        tt = (obj.tp-obj.dtBDS-te) * SMU2S; %信号传播时间,s,需要将定位时间转化为北斗时
        carrAcc = channel.carrAccS + channel.carrAccR;
        dCarrFreq = carrAcc * (dt-0.5e-3);
        doppler = (channel.carrFreq+dCarrFreq)*Cdf/Fca + obj.deltaFreq; %归一化,接收机钟快使多普勒变小(发生在下变频)
        satmeas(k,7:8) = satmeasCorr(tt, doppler, corr);
    end
end

end