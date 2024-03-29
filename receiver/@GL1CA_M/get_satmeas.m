function [satpv, satmeas] = get_satmeas(obj)
% 获取卫星测量
% satpv:[x,y,z,vx,vy,vz]
% satmeas:[rho,rhodot,phase],元胞数组,每个元素为一个天线

Fca = 1575.42e6; %载波频率
Lca = 0.190293672798365; %载波波长,m

SMU2S = [1;1e-3;1e-6]; %[s,ms,us]到s
Cdf = 1 + obj.deltaFreq; %跟踪频率到真实频率的系数
Ddf = obj.deltaFreq / Cdf; %df/(1+df)
dtp = (obj.ta-obj.tp)*SMU2S * Cdf; %当前采样点到定位点的时间差(接收机钟)

satpv = NaN(obj.chN,6);
corr = cell(obj.chN,1);
carrAccS = NaN(obj.chN,1);
satmeas = cell(1,obj.anN);
for m=1:obj.anN
    satmeas{m} = NaN(obj.chN,3);
    for k=1:obj.chN
        channel = obj.channels(k,m);
        if channel.state>=2 %只要跟踪上的通道都能测,这里不用管信号质量,选星额外来做
            %----计算定位点所接到码的发射时间
            dn = mod(obj.buffHead-channel.trackDataTail+1, obj.buffSize) - 1; %恰好超前一个采样点时dn=-1
            dtc = dn / obj.sampleFreq; %当前采样点到跟踪点的时间差(接收机钟)
            dt = dtc - dtp; %定位点到跟踪点的时间差(接收机钟)
            codePhase = channel.remCodePhase + channel.codeNco*dt; %定位点码相位
            te = [floor(channel.tc0/1e3), mod(channel.tc0,1e3), 0] + ...
                 [0, floor(codePhase/1023), mod(codePhase/1023,1)*1e3]; %定位点码发射时间
            %----计算信号发射时刻卫星位置速度加速度,卫星运动引起的载波频率变化率(不重复算)
            if isnan(satpv(k,1))
                [rsvsas, corr{k}] = LNAV.rsvsas_emit(channel.ephe(5:end), te, obj.rp, obj.vp, obj.iono, obj.pos);
                satpv(k,:) = rsvsas(1:6);
                rhodotdot = rhodotdot_cal(rsvsas, obj.rp, obj.vp, obj.geogInfo);
                carrAccS(k) = -rhodotdot/Lca / Cdf;
            end
            channel.carrAccS = carrAccS(k); %设置跟踪通道载波频率变化率,Hz/s
            %----计算伪距伪距率
            tt = (obj.tp-te) * SMU2S; %信号传播时间,s
            carrAcc = channel.carrAccS + channel.carrAccR; %载波加速度(在大加速度时需考虑定位点与跟踪点时间间隔内的多普勒变化)
            dCarrFreq = carrAcc * (dt-0.5e-3); %跟踪点测的载波频率实际上是下个1ms积分时间中间时刻的载波频率
            doppler = (channel.carrFreq+dCarrFreq)*Cdf/Fca + obj.deltaFreq; %归一化,接收机钟快使多普勒变小(发生在下变频)
            satmeas{m}(k,1:2) = satmeasCorr(tt, doppler, corr{k});
            %----计算载波相位(在外面转化成距离时直接乘以标称波长)
            clockError = obj.clockError + dt*Ddf; %到定位点累积了多少钟差
            carrPhase = channel.carrCirc - channel.remCarrPhase - channel.carrNco*dt; %定位点的载波相位(累积负频率)
            carrPhase = carrPhaseCorr(carrPhase, corr{k}, Fca); %载波相位校正
            carrPhase = carrPhase - clockError*Fca; %补偿接收机钟差
            dL = satmeas{m}(k,1) - carrPhase*Lca; %载波相位对应的距离与伪距之差
            if abs(dL)>300 %如果差大于300m,则进行调整,令载波相位与伪距匹配
                dcarrCirc = round(dL/Lca); %载波相位整周修正量
                channel.carrCirc = channel.carrCirc + dcarrCirc; %修载波相位整周计数
                carrPhase = carrPhase + dcarrCirc; %修载波相位
            end
            satmeas{m}(k,3) = carrPhase; %(当修接收机钟的时候,载波相位会漂)
        end
    end
end

end