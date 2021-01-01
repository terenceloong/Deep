% GPS信号仿真

clear
clc
fclose('all');

%% 参数
startTime = [2020,7,27,11,16,14]; %仿真开始时间
zone = 8; %时区
runTime = 60; %仿真运行时间,s
step = 5; %仿真步长,ms
eleMask = 10; %截至高度角,deg
clockError = 4e-3; %接收机钟频差,正数表示钟快,ppm
sampleFreq = 4e6; %采样频率,Hz
gain = 100; %增益

p0 = [45.7364, 126.70775, 165];
rp = lla2ecef(p0);

satMode = 0; %卫星模式,0-根据截至高度角自动计算,1-指定卫星列表
svList = [3,17,19,28];
svN = length(svList); %可见卫星数目

%% 信号配置
signal_conf.cnrMode = 1;
signal_conf.cnrValue = 45;
signal_conf.sampleFreq = sampleFreq;

%% 创建信号仿真对象
sats = GPS.L1CA.signalSim.empty; %创建类的空矩阵
for k=1:32
    sats(k) = GPS.L1CA.signalSim(k, signal_conf);
end
sats = sats'; %转化成列向量

%% 获取星历
startTime_utc = startTime - [0,0,0,zone,0,0]; %仿真开始的UTC时间
filename = GPS.ephemeris.download('~temp\ephemeris', datestr(startTime_utc,'yyyy-mm-dd'));
ephe = RINEX.read_N2(filename);
startTime_gps = UTC2GPS(startTime, zone); %仿真开始的GPS时间
startTime_tow = startTime_gps(2); %周内秒数
for k=1:32
    if ~isempty(ephe.sv{k}) && ephe.sv{k}(1).health==0 %保证有星历并且卫星健康
        index = find([ephe.sv{k}.TOW]<=startTime_tow, 1, 'last'); %根据tow找到最近星历所在的行
        ephe_cell = struct2cell(ephe.sv{k}(index)); %星历结构体转化成元胞数组
        sats(k).ephe = [ephe_cell{:}]; %为每颗卫星赋星历
        sats(k).update_message(startTime_tow-0.07); %更新导航电文
    end
end

%% 控制参数
loopN = runTime*1000 / step; %循环次数
sampleN = sampleFreq/1000 * step; %一个循环的采样点数
clockErrorFactor = 1 / (1 + clockError*1e-6); %用来接收机钟走了n秒实际走了多长时间
ele = zeros(1,32); %卫星高度角
te0 = zeros(32,3); %上次发射时间(卫星钟),[s,ms,us]
tr0 = [startTime_tow,0,0]; %上次接收机钟时间,[s,ms,us]

%% 创建文件
startTime_str = sprintf('%4d%02d%02d_%02d%02d%02d', startTime);
fileID = fopen(['SIM_',startTime_str,'_ch1.dat'], 'w');

%% 创建进度条
waitbar_str = ['s/',num2str(runTime),'s']; %进度条中不变的字符串
f = waitbar(0, ['0',waitbar_str]);

%% 数据生成
tic
for k=1:loopN
    % 整秒更新卫星高度角,更新可见卫星列表
    tn0 = (k-1) * step / 1000; %上次接收机钟运行时间
    if mod(tn0,1)==0
        waitbar((tn0+1)/runTime, f, [sprintf('%d',tn0+1),waitbar_str]); %更新进度条
        %----更新所有卫星高度角
        tr0_real = timeCarry(sec2smu(tn0 * clockErrorFactor)); 
        tr0_real(1) = tr0_real(1) + startTime_tow; %上次真实时间
        for PRN=1:32
            sats(PRN).update_aziele(tr0(1), ecef2lla(rp));
            ele(PRN) = sats(PRN).ele;
        end
        %----选择卫星
        if satMode==0 %根据截至高度角选卫星
            svList = find(ele>eleMask); %更新可见卫星列表
            svN = length(svList); %可见卫星数目
            for PRN=svList
                te0(PRN,:) = LNAV.transmit_time(sats(PRN).ephe(5:25), tr0_real, rp); %记录发射时间
            end
        else %指定卫星
            if tn0==0 %只在开始时算一次
                for PRN=svList
                    te0(PRN,:) = LNAV.transmit_time(sats(PRN).ephe(5:25), tr0_real, rp); %记录发射时间
                end
            end
        end
    end
    
    % 生成可见卫星的信号
    tn = k * step / 1000; %当前接收机钟运行时间
    tr = timeCarry(sec2smu(tn));
    tr(1) = tr(1) + startTime_tow; %当前接收机钟时间
    tr_real = timeCarry(sec2smu(tn * clockErrorFactor));
    tr_real(1) = tr_real(1) + startTime_tow; %当前真实时间
    comSigI = randn(1,sampleN); %合成信号
    comSigQ = randn(1,sampleN);
    for m=1:svN
        PRN = svList(m); %卫星号
        te = LNAV.transmit_time(sats(PRN).ephe(5:25), tr_real, rp); %计算发射时间
        [sigI, sigQ] = sats(PRN).gene_signal(te0(PRN,:), te, tr0, tr, sampleN); %生成信号
        comSigI = comSigI + sigI;
        comSigQ = comSigQ + sigQ;
        te0(PRN,:) = te; %记录发射时间
    end
    tr0 = tr; %记录接收机钟时间
    
    % 写入文件
    fwrite(fileID, int16([comSigI;comSigQ]*gain), 'int16');
end
toc

%% 关闭文件,关闭进度条
fclose(fileID);
close(f);