%% GPS L1 C/A�����߽��ջ�����

%%
clear
clc
fclose('all'); %�ر�֮ǰ�򿪵������ļ�

Ts = 60; %�ܴ���ʱ��,s
To = 0; %ƫ��ʱ��,s
svList = []; %[10,15,20,24]
p0 = [45.730952, 126.624970, 212]; %���µĳ�ʼλ��
% p0 = [38.05, 114.55222, 132];

%% ѡ��GNSS�����ļ�
valid_prefix = 'B210-SIM-'; %�ļ�����Чǰ׺
[file, path] = uigetfile('*.dat', 'ѡ��GNSS�����ļ�'); %�ļ�ѡ��Ի���
if ~ischar(file) || ~contains(valid_prefix, strtok(file,'_'))
    error('File error!')
end
if ~(strcmp(file(end-6:end-4),'ch1'))
    error('File error!')
end
data_file_1 = [path, file(1:end-7), 'ch1.dat']; %�����ļ�����·��,path����\
data_file_2 = [path, file(1:end-7), 'ch2.dat'];

%% ��������
% ����ʵ������޸�.
msToProcess = Ts*1000; %������ʱ��
sampleOffset = To*4e6; %����ǰ���ٸ�������
sampleFreq = 4e6; %���ջ�����Ƶ��
blockSize = sampleFreq*0.001; %һ�������(1ms)�Ĳ�������

%% ��ȡ���ջ���ʼʱ��
[~, filename] = strtok(file,'_'); %�ļ���ȥ��ǰ׺ʣ�µĲ���
filetime = filename(2:16); %�ļ�ʱ��
tf = sscanf(filetime, '%4d%02d%02d_%02d%02d%02d')'; %�����ļ���ʼʱ��(����ʱ������)
tg = UTC2GPS(tf, 8); %UTCʱ��ת��ΪGPSʱ��
ta = [tg(2),0,0] + sample2dt(sampleOffset, sampleFreq); %���ջ���ʼʱ��,[s,ms,us]
ta = timeCarry(round(ta,2)); %��λ,΢�뱣��2λС��

%% ��ȡ����
% ��ָ������洢���ļ���.
almanac_file = GPS.almanac.download('~temp\almanac', tg); %��������
almanac = GPS.almanac.read(almanac_file); %������

%% ���ջ�����
% ����ʵ�������޸�.
receiver_conf.Tms = msToProcess; %���ջ�������ʱ��,ms
receiver_conf.sampleFreq = sampleFreq; %����Ƶ��,Hz
receiver_conf.anN = 2; %��������
receiver_conf.blockSize = blockSize; %һ�������(1ms)�Ĳ�������
receiver_conf.blockNum = 50; %����������
receiver_conf.week = tg(1); %��ǰGPS����
receiver_conf.ta = ta; %���ջ���ʼʱ��,[s,ms,us]
receiver_conf.CN0Thr = [37,33,30,18]; %�������ֵ
receiver_conf.almanac = almanac; %����
receiver_conf.eleMask = 10; %�߶Ƚ���ֵ
receiver_conf.svList = svList; %���������б�
receiver_conf.acqTime = 2; %�������õ����ݳ���,ms
receiver_conf.acqThreshold = 1.4; %������ֵ,��߷���ڶ����ı�ֵ
receiver_conf.acqFreqMax = 5e3; %�������Ƶ��,Hz
receiver_conf.p0 = p0; %��ʼλ��,γ����
receiver_conf.dtpos = 10; %��λʱ����,ms

%% �������ջ�����
nCoV = GL1CA_M(receiver_conf);

%% Ԥ������
% ��ѡ����,������ǰ���ж�λ.
% ��ָ�������洢���ļ���.
% �����ļ����Բ�����,����ʱ���Զ�����.
% ע�͵����ʱͬʱҪע�͵�����ı�������.
ephemeris_file = ['~temp\ephemeris\',filetime,'.mat']; %�ļ���
nCoV.set_ephemeris(ephemeris_file);

%% ���ļ�,����������
fileID_1 = fopen(data_file_1, 'r');
fseek(fileID_1, round(sampleOffset*4), 'bof'); %��ȡ�����ܳ����ļ�ָ���Ʋ���ȥ
if int64(ftell(fileID_1))~=int64(sampleOffset*4) %����ļ�ָ���Ƿ��ƹ�ȥ��
    error('Sample offset error!')
end
fileID_2 = fopen(data_file_2, 'r');
fseek(fileID_2, round(sampleOffset*4), 'bof'); %��ȡ�����ܳ����ļ�ָ���Ʋ���ȥ
if int64(ftell(fileID_2))~=int64(sampleOffset*4) %����ļ�ָ���Ƿ��ƹ�ȥ��
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
    data1 = fread(fileID_1, [2,blockSize], 'int16'); %���ļ�������
    data2 = fread(fileID_2, [2,blockSize], 'int16');
    nCoV.run(cat(3,data1,data2)); %���ջ���������
end
nCoV.clean_storage;
% nCoV.get_result;
toc

%% �ر��ļ�,�رս�����
fclose(fileID_1);
fclose(fileID_2);
close(f);

%% ��������
% ��ǰ���Ԥ��������Ӧ.
nCoV.save_ephemeris(ephemeris_file);

%% �������
data_file = data_file_1;
clearvars -except data_file receiver_conf nCoV tf p0

%% ����������ͼ
nCoV.interact_constellation;

%% ������
save('~temp\result\result.mat')