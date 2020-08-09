%% GPS L1 C/A & BDS B1C�����������

%%
clear
clc
fclose('all'); %�ر�֮ǰ�򿪵������ļ�

%% ѡ��IMU�����ļ�
imu = SBG_imu_read(0);
imu(:,5:7) = imu(:,5:7) / 9.806370601248435;
gyro0 = mean(imu(1:200,2:4)); %�����ʼ������ƫ
% psi0 = input('psi0 = '); %�����ʼ�����,deg
psi0 = 180;

%% ѡ��GNSS�����ļ�
valid_prefix = 'B210-'; %�ļ�����Чǰ׺
[file, path] = uigetfile('*.dat', 'ѡ��GNSS�����ļ�'); %�ļ�ѡ��Ի���
if ~ischar(file) || ~contains(valid_prefix, strtok(file,'_'))
    error('File error!')
end
data_file = [path, file]; %�����ļ�����·��,path����\

% data_file = 'C:\Users\longt\Desktop\B210_20190823_194010_ch1.dat'; %ָ���ļ�,���ڲ���
% data_file = 'C:\Users\longt\Desktop\GNSS data\B210_20200727_111615_ch1.dat';

%% ��������
% ����ʵ������޸�.
msToProcess = 300*1000; %������ʱ��
sampleOffset = 0*4e6; %����ǰ���ٸ�������
sampleFreq = 4e6; %���ջ�����Ƶ��
blockSize = sampleFreq*0.001; %һ�������(1ms)�Ĳ�������
p0 = [45.730952, 126.624970, 212]; %��ʼλ��,�����ر�ȷ

%% ��ȡ���ջ���ʼʱ��
tf = sscanf(data_file((end-22):(end-8)), '%4d%02d%02d_%02d%02d%02d')'; %�����ļ���ʼʱ��(����ʱ������)
% GPSʱ
tg = UTC2GPS(tf, 8); %UTCʱ��ת��ΪGPSʱ��,��+��
tag = [tg(2),0,0] + sample2dt(sampleOffset, sampleFreq); %���ջ���ʼʱ��,[s,ms,us]
tag = timeCarry(round(tag,2)); %��λ,΢�뱣��2λС��
% ����ʱ
tb = UTC2BDT(tf, 8); %UTCʱ��ת��ΪBDTʱ��,��+��
% tab = [tb(2),0,0] + sample2dt(sampleOffset, sampleFreq);
% tab = timeCarry(round(tab,2));

%% ��ȡ����
% ��ָ������洢���ļ���.
almanac_file_GPS = GPS.almanac.download('~temp\almanac', tg); %��������
almanac_GPS = GPS.almanac.read(almanac_file_GPS); %������
date = sprintf('%4d-%02d-%02d', tf(1),tf(2),tf(3)); %��ǰ����
almanac_file_BDS = BDS.almanac.download('~temp\almanac', date); %��������
almanac_BDS = BDS.almanac.read(almanac_file_BDS); %������
index = ismember(almanac_BDS(:,1), [19:30,32:46]);
almanac_BDS = almanac_BDS(index,:); %ֻҪ�����������ǵ�����

%% ���ջ�����
% ����ʵ�������޸�.
receiver_conf.Tms = msToProcess; %���ջ�������ʱ��,ms
receiver_conf.sampleFreq = sampleFreq; %����Ƶ��,Hz
receiver_conf.blockSize = blockSize; %һ�������(1ms)�Ĳ�������
receiver_conf.blockNum = 100; %����������
receiver_conf.GPSweek = tg(1); %��ǰGPS����
receiver_conf.BDSweek = tb(1); %��ǰ��������
receiver_conf.ta = tag; %���ջ���ʼʱ��,[s,ms,us],ʹ��GPSʱ����Ϊʱ���׼
receiver_conf.GPSflag = 1; %�Ƿ�����GPS
receiver_conf.BDSflag = 1; %�Ƿ����ñ���
%-------------------------------------------------------------------------%
receiver_conf.GPS.almanac = almanac_GPS; %����
receiver_conf.GPS.eleMask = 10; %�߶Ƚ���ֵ
receiver_conf.GPS.svList = []; %���������б�,[10,15,20,24]
receiver_conf.GPS.acqTime = 2; %�������õ����ݳ���,ms
receiver_conf.GPS.acqThreshold = 1.4; %������ֵ,��߷���ڶ����ı�ֵ
receiver_conf.GPS.acqFreqMax = 5e3; %�������Ƶ��,Hz
%-------------------------------------------------------------------------%
receiver_conf.BDS.almanac = almanac_BDS; %����
receiver_conf.BDS.eleMask = 10; %�߶Ƚ���ֵ
receiver_conf.BDS.svList = []; %���������б�,[19,20,29,35,38,40,44]
receiver_conf.BDS.acqThreshold = 1.4; %������ֵ,��߷���ڶ����ı�ֵ
receiver_conf.BDS.acqFreqMax = 5e3; %�������Ƶ��,Hz
%-------------------------------------------------------------------------%
receiver_conf.p0 = p0; %��ʼλ��,γ����
receiver_conf.dtpos = 10; %��λʱ����,ms

%% �����˲�������
para.dt = 0.01; %s,����IMU������������
para.gyro0 = gyro0; %deg/s
para.p0 = [0,0,0];
para.v0 = [0,0,0];
para.a0 = [psi0,0,0]; %deg
para.P0_att = 1; %deg
para.P0_vel = 1; %m/s
para.P0_pos = 5; %m
para.P0_dtr = 2e-8; %s
para.P0_dtv = 3e-9; %s/s
para.P0_gyro = 0.2; %deg/s
para.P0_acc = 2e-3; %g
para.Q_gyro = 0.2; %deg/s
para.Q_acc = 2e-3; %g
para.Q_dtv = 0.01e-9; %1/s
para.Q_dg = 0.02; %deg/s/s
para.Q_da = 0.2e-3; %g/s
para.sigma_gyro = 0.15; %deg/s

%% �������ջ�����
nCoV = GL1CA_BB1C_S(receiver_conf);

%% Ԥ������
ephemeris_file = ['~temp\ephemeris\',data_file((end-22):(end-8)),'.mat']; %�ļ���
nCoV.set_ephemeris(ephemeris_file);

%% ���ļ�,����������
fileID = fopen(data_file, 'r');
fseek(fileID, round(sampleOffset*4), 'bof'); %��ȡ�����ܳ����ļ�ָ���Ʋ���ȥ
if int64(ftell(fileID))~=int64(sampleOffset*4) %����ļ�ָ���Ƿ��ƹ�ȥ��
    error('Sample offset error!')
end
waitbar_str = ['s/',num2str(msToProcess/1000),'s']; %�������в�����ַ���
f = waitbar(0, ['0',waitbar_str]);

%% ���ջ�����
tic
for t=1:msToProcess
    if mod(t,1000)==0 %1s����
        waitbar(t/msToProcess, f, [sprintf('%d',t/1000),waitbar_str]); %���½�����
    end
    data = fread(fileID, [2,blockSize], 'int16'); %���ļ�������
    nCoV.run(data); %���ջ���������
    %---------------------------------------------------------------------%
    if nCoV.state==3 %�����ʱ,����һ�ζ�λ��Ϊ�������´ζ�λʱ���IMU����
        if isnan(nCoV.tp(1)) %��λ��tp����NaN
            ki = ki+1; %IMU������1
            nCoV.imu_input(imu(ki,1), imu(ki,2:7)); %����IMU����
        end
    elseif nCoV.state==1 %�����ջ���ʼ����ɺ���������
        ki = find(imu(:,1)>nCoV.ta*[1;1e-3;1e-6], 1); %IMU����
        if isempty(ki) || (imu(ki,1)-nCoV.ta(1))>1
            error('Data mismatch!')
        end
        nCoV.imu_input(imu(ki,1), imu(ki,2:7)); %����IMU����
        para.p0 = nCoV.pos;
        nCoV.navFilter = filter_single(para); %��ʼ�������˲���
        nCoV.deepMode = 2; %���������ģʽ
        nCoV.channel_deep; %ͨ���л�����ϸ��ٻ�·
        nCoV.state = 3; %���ջ����������
    end
end
nCoV.clean_storage;
toc

%% �ر��ļ�,�رս�����
fclose(fileID);
close(f);

%% ��������
nCoV.save_ephemeris(ephemeris_file);

%% �������
clearvars -except data_file receiver_conf nCoV tf p0 imu

%% ����������ͼ
nCoV.interact_constellation;

%% ������
save('~temp\result.mat')