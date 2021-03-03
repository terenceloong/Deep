% GPS信号仿真

clearvars -except IFsim_conf IFsim_GUIflag
clc
fclose('all');

%% 中频信号仿真配置预设值
% 使用GUI时外部会生成IFsim_conf,并将IFsim_GUIflag置1
if ~exist('IFsim_GUIflag','var') || IFsim_GUIflag~=1
    IFsim_conf.startTime = [2020,7,27,11,16,14]; %仿真开始时间
    IFsim_conf.zone = 8; %时区
    IFsim_conf.runTime = 120; %仿真运行时间,s
    IFsim_conf.step = 0.005; %仿真步长,s
    IFsim_conf.eleMask = 10; %截至高度角,deg
    IFsim_conf.clockError = 4e-9; %接收机钟频差,正数表示钟快
    IFsim_conf.sampleFreq = 4e6; %采样频率,Hz
    IFsim_conf.gain = 100; %增益
    IFsim_conf.trajMode = 1; %轨迹模式,0-静止,1-动态
    IFsim_conf.p0 = [45.7364, 126.70775, 165]; %静止位置
    IFsim_conf.trajName = 'traj004'; %轨迹名
    IFsim_conf.satMode = 0; %卫星模式,0-根据截至高度角自动计算,1-指定卫星列表
    IFsim_conf.svList = [3,17,19,28]; %卫星列表
end
if exist('IFsim_GUIflag','var')
    IFsim_GUIflag = 0;
end

%% 参数
startTime = IFsim_conf.startTime; %仿真开始时间
zone = IFsim_conf.zone; %时区
runTime = IFsim_conf.runTime; %仿真运行时间,s
step = IFsim_conf.step; %仿真步长,s
eleMask = IFsim_conf.eleMask; %截至高度角,deg
clockError = IFsim_conf.clockError; %接收机钟频差,正数表示钟快
sampleFreq = IFsim_conf.sampleFreq; %采样频率,Hz
gain = IFsim_conf.gain; %增益
trajMode = IFsim_conf.trajMode; %轨迹模式,0-静止,1-动态
p0 = IFsim_conf.p0; %静止位置
trajName = IFsim_conf.trajName; %轨迹名
satMode = IFsim_conf.satMode; %卫星模式,0-根据截至高度角自动计算,1-指定卫星列表
svList = IFsim_conf.svList; %卫星列表

%% 加载轨迹
if trajMode==0
    rp = lla2ecef(p0);
    traj = ones(runTime/step+1,1) * [rp,0,0,0]; %生成每个时刻的位置姿态,姿态默认都是0
else
    load(['~temp\traj\',trajName,'.mat']) %加载轨迹
    if trajGene_conf.dt~=step %轨迹的步长必须与仿真步长相等
        error('Step mismatch!')
    end
    if trajGene_conf.Ts<runTime %轨迹时间必须大于仿真时间
        error('runTime error!')
    end
end

%% 轨迹插值函数
t = (0:step:runTime)'; %时间序列
n = length(t);
P1 = griddedInterpolant(t,traj(1:n,1),'pchip');
P2 = griddedInterpolant(t,traj(1:n,2),'pchip');
P3 = griddedInterpolant(t,traj(1:n,3),'pchip');

%% 仿真时间
startTime_utc = startTime - [0,0,0,zone,0,0]; %仿真开始的UTC时间
startTime_gps = UTC2GPS(startTime, zone); %仿真开始的GPS时间
startTime_tow = startTime_gps(2); %周内秒数

%% 创建信号仿真对象
sats = GPS.L1CA.signalSim.empty; %创建类的空矩阵
for k=1:32
    sats(k) = GPS.L1CA.signalSim(k, sampleFreq, sampleFreq*step*2);
end
sats = sats'; %转化成列向量

%% 设置载噪比模式
%----所有卫星载噪比设置成常值
% for k=1:32
%     sats(k).cnrMode = 1;
%     sats(k).cnrValue = 48;
% end
%----为指定卫星设置载噪比表
% cnrTable1 = [0, 10, 15, 25, 30;
%             55, 55, 35, 35, 25;
%              0, -4,  0, -2,  0];
% cnrTable1(1,2:end) = cnrTable1(1,2:end) + startTime_tow;
% sats(17).cnrMode = 2;
% sats(17).cnrTable = cnrTable1;

%% 获取星历
filename = GPS.ephemeris.download('~temp\ephemeris', datestr(startTime_utc,'yyyy-mm-dd'));
ephe = RINEX.read_N2(filename);
for k=1:32
    if ~isempty(ephe.sv{k}) && ephe.sv{k}(1).health==0 %保证有星历并且卫星健康
        index = find([ephe.sv{k}.TOW]<=startTime_tow, 1, 'last'); %根据tow找到最近星历所在的行
        ephe_cell = struct2cell(ephe.sv{k}(index)); %星历结构体转化成元胞数组
        sats(k).ephe = [ephe_cell{:}]; %为每颗卫星赋星历
        sats(k).update_message(startTime_tow-0.07); %更新导航电文
    end
end

%% 控制参数
step2 = step*2; %二次函数插值,一次算两步
loopN = runTime / step2; %循环次数
sampleN = sampleFreq * step2; %一个循环的采样点数
clockErrorFactor = 1 / (1 + clockError); %用来接收机钟走了n秒实际走了多长时间
clock0 = [startTime_tow,0,0]; %初始接收机钟时间(无钟差),[s,ms,us]
ele = zeros(1,32); %卫星高度角
te0 = zeros(32,3); %上次发射时间(卫星钟),[s,ms,us]
tr0 = clock0; %上次接收机钟时间,[s,ms,us]

%% 创建文件
startTime_str = sprintf('%4d%02d%02d_%02d%02d%02d', startTime);
if trajMode==0
    fileID = fopen(['~temp\data\SIM_',startTime_str,'_000.dat'], 'w');
else
    fileID = fopen(['~temp\data\SIM_',startTime_str,'_',trajName(end-2:end),'.dat'], 'w');
end

%% 创建进度条
waitbar_str = ['s/',num2str(runTime),'s']; %进度条中不变的字符串
f = waitbar(0, ['0',waitbar_str]);

%% 数据生成
tic
for k=1:loopN
    % 整秒更新卫星高度角,更新可见卫星列表
    tn0 = (k-1)*step2; %上次接收机钟运行时间
    dt0 = tn0 * clockErrorFactor; %上次实际运行时间
    if mod(tn0,1)==0
        waitbar((tn0+1)/runTime, f, [sprintf('%d',tn0+1),waitbar_str]); %更新进度条
        %----更新所有卫星高度角
        rp0 = [P1(dt0), P2(dt0), P3(dt0)]; %上次位置
        tr0_real = timeCarry(sec2smu(dt0)) + clock0; %上次真实时间
        for PRN=1:32
            sats(PRN).update_aziele(tr0_real(1), ecef2lla(rp0));
            ele(PRN) = sats(PRN).ele;
        end
        %----选择卫星
        if satMode==0 %根据截至高度角选卫星
            svList = find(ele>eleMask); %更新可见卫星列表
            svN = length(svList); %可见卫星数目
            for PRN=svList
                te0(PRN,:) = LNAV.transmit_time(sats(PRN).ephe(5:25), tr0_real, rp0); %记录发射时间
            end
        else %指定卫星
            if tn0==0 %只在开始时算一次
                svN = length(svList); %可见卫星数目
                for PRN=svList
                    te0(PRN,:) = LNAV.transmit_time(sats(PRN).ephe(5:25), tr0_real, rp0); %记录发射时间
                end
            end
        end
    end
    
    % 生成可见卫星的信号
    tn1 = k*step2 - step; %中间接收机钟运行时间
    dt1 = tn1 * clockErrorFactor; %中间实际运行时间
    tr1 = timeCarry(sec2smu(tn1)) + clock0; %中间接收机钟时间
    tr1_real = timeCarry(sec2smu(dt1)) + clock0; %中间真实时间
    tn2 = k*step2; %当前接收机钟运行时间
    dt2 = tn2 * clockErrorFactor; %当前实际运行时间
    tr2 = timeCarry(sec2smu(tn2)) + clock0; %当前接收机钟时间
    tr2_real = timeCarry(sec2smu(dt2)) + clock0; %当前真实时间
    rp1 = [P1(dt1), P2(dt1), P3(dt1)]; %中间位置
    rp2 = [P1(dt2), P2(dt2), P3(dt2)]; %当前位置
    att = traj(2*k-1,4:6); %姿态,deg
    comSigI = randn(1,sampleN); %合成信号
    comSigQ = randn(1,sampleN);
    for m=1:svN
        PRN = svList(m); %卫星号
        te1 = LNAV.transmit_time(sats(PRN).ephe(5:25), tr1_real, rp1); %计算发射时间
        te2 = LNAV.transmit_time(sats(PRN).ephe(5:25), tr2_real, rp2);
        [sigI, sigQ] = sats(PRN).gene_signal([te0(PRN,:);te1;te2], [tr0;tr1;tr2], att); %生成信号
        comSigI = comSigI + sigI;
        comSigQ = comSigQ + sigQ;
        te0(PRN,:) = te2; %记录发射时间
    end
    tr0 = tr2; %记录接收机钟时间
    
    % 写入文件
    fwrite(fileID, int16([comSigI;comSigQ]*gain), 'int16');
end
toc

%% 关闭文件,关闭进度条
fclose(fileID);
close(f);

%% 清除变量
clearvars