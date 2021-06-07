% 参见《OEM6 Family Firmware Reference Manual》

clear
clc

%% 选文件
[file, path] = uigetfile('*.gps;*.dat;*.DAT', '选择NovAtel log文件'); %文件选择对话框
if ~ischar(file)
    error('File error!')
end
data_file = [path, file]; %数据文件完整路径,path最后带\

%% 读文件
fileID = fopen(data_file);
stream = fread(fileID, 'uint8=>uint8');
fclose(fileID);
n = length(stream); %总字节数

%% 统计帧数
cnt = 0; %记有多少帧消息
k = 1;
while 1
    if k+9>n %保证读到消息长度
        break
    end
    if stream(k)==0xAA && stream(k+1)==0x44 && stream(k+2)==0x12 %帧头
        hl = double(stream(k+3)); %帧头长度
        ml = double(typecast(stream(k+8:k+9),'uint16')); %消息长度
        if k+hl+ml+4>n+1 %保证有个完整帧
            break
        end
        cnt = cnt + 1;
        k = k + hl+ml+4;
    else
        k = k+1;
    end
end

%% 统计消息头,P23
Header = zeros(cnt,10);
ih = 1; %存储位置

streamIndex = zeros(cnt,2); %一帧消息头和尾的索引
k = 1;
while 1
    if k+9>n %保证读到消息长度
        break
    end
    if stream(k)==0xAA && stream(k+1)==0x44 && stream(k+2)==0x12 %帧头
        hl = double(stream(k+3)); %帧头长度
        ml = double(typecast(stream(k+8:k+9),'uint16')); %消息长度
        if k+hl+ml+4>n+1 %保证有个完整帧
            break
        end
        frame = stream(k:k+hl+ml+3); %一帧消息
        %---------------------------------------------------------------------%
        streamIndex(ih,1) = k; %帧头索引
        streamIndex(ih,2) = k+hl+ml+3; %帧尾索引
        Header(ih,1)  = typecast(frame(5:6),'uint16');   %msgID
        Header(ih,2)  = frame(7);                        %msgType
        Header(ih,3)  = frame(8);                        %portAddr
        Header(ih,4)  = typecast(frame(9:10),'uint16');  %msgLength
        Header(ih,5)  = typecast(frame(11:12),'uint16'); %sequence
        Header(ih,6)  = double(frame(13))/2;             %idleTime
        Header(ih,7)  = frame(14);                       %timeStatus
        Header(ih,8)  = typecast(frame(15:16),'uint16'); %GPSweek
        Header(ih,9)  = typecast(frame(17:20),'uint32'); %GPSms
        Header(ih,10) = typecast(frame(21:24),'uint32'); %recStatus,0表示没有错误
        ih = ih + 1;
        %---------------------------------------------------------------------%
        k = k + hl+ml+4;
    else
        k = k+1;
    end
end

Header = table(Header(:,1),Header(:,2),Header(:,3),Header(:,4),Header(:,5),...
               Header(:,6),Header(:,7),Header(:,8),Header(:,9),Header(:,10),...
'VariableNames',{'msgID','msgType','portAddr','msgLength','sequence',...
                'idleTime','timeStatus','GPSweek','GPSms','recStatus'});

y = streamIndex(2:end,1) - streamIndex(1:end-1,2); %当前帧头减前一帧帧尾应该为1
if any(y~=1)
    disp('data lost!')
end
messageID = unique(Header.msgID); %总共有多少种消息
% 7-GPSEPHEM
% 42-BESTPOS
% 43-RANGE(长)
% 101-TIME
% 140-RANGECMP(短)
% 243-PSRXYZ
% 723-GLOEPHEMERIS
% 971-HEADING
% 1696-BDSEPHEMERIS

%% 解析
N42 = sum(Header.msgID==42); %消息数量
BESTPOS = zeros(N42,19);
i42 = 1; %存储位置

N101 = sum(Header.msgID==101);
TIME = zeros(N101,11);
i101 = 1;

N140 = sum(Header.msgID==140);
RANGECMP = cell(N140,2);
i140 = 1;

N243 = sum(Header.msgID==243);
PSRXYZ = zeros(N243,24);
i243 = 1;

N971 = sum(Header.msgID==971);
HEADING = zeros(N971,15);
i971 = 1;

k = 1;
while 1
    if k+9>n %保证读到消息长度
        break
    end
    if stream(k)==0xAA && stream(k+1)==0x44 && stream(k+2)==0x12 %帧头
        hl = double(stream(k+3)); %帧头长度
        ml = double(typecast(stream(k+8:k+9),'uint16')); %消息长度
        if k+hl+ml+4>n+1 %保证有个完整帧
            break
        end
    end
    frame = stream(k:k+hl+ml+3); %一帧消息
    ID = typecast(frame(5:6),'uint16'); %Message ID
    %---------------------------------------------------------------------%
    switch ID
        case 42 %BESTPOS,P394
            BESTPOS(i42,1)  = typecast(frame(hl+(1:4)),'uint32');   %solState,0表示解算完成
            BESTPOS(i42,2)  = typecast(frame(hl+(5:8)),'uint32');   %posType
            BESTPOS(i42,3)  = typecast(frame(hl+(9:16)),'double');  %lat
            BESTPOS(i42,4)  = typecast(frame(hl+(17:24)),'double'); %lon
            BESTPOS(i42,5)  = typecast(frame(hl+(25:32)),'double'); %h
            BESTPOS(i42,6)  = typecast(frame(hl+(33:36)),'single'); %undulation
            BESTPOS(i42,7)  = typecast(frame(hl+(37:40)),'uint32'); %datumID
            BESTPOS(i42,8)  = typecast(frame(hl+(41:44)),'single'); %lat sigma
            BESTPOS(i42,9)  = typecast(frame(hl+(45:48)),'single'); %lon sigma
            BESTPOS(i42,10) = typecast(frame(hl+(49:52)),'single'); %h sigma
            BESTPOS(i42,11) = typecast(frame(hl+(57:60)),'single'); %diff age
            BESTPOS(i42,12) = typecast(frame(hl+(61:64)),'single'); %sol age
            BESTPOS(i42,13) = frame(hl+65);                         %trackSVs
            BESTPOS(i42,14) = frame(hl+66);                         %solSVs
            BESTPOS(i42,15) = frame(hl+67);                         %solL1SVs
            BESTPOS(i42,16) = frame(hl+68);                         %solMultiSVs
            BESTPOS(i42,17) = frame(hl+70);                         %ext sol state
            BESTPOS(i42,18) = frame(hl+71);                         %Galileo and BeiDou sig mask
            BESTPOS(i42,19) = frame(hl+72);                         %GPS and GLONASS sig mask
            i42 = i42 + 1;
        case 101 %TIME,P716
            TIME(i101,1)  = typecast(frame(hl+(1:4)),'uint32');   %clock status
            TIME(i101,2)  = typecast(frame(hl+(5:12)),'double');  %offset
            TIME(i101,3)  = typecast(frame(hl+(13:20)),'double'); %offset sigma
            TIME(i101,4)  = typecast(frame(hl+(21:28)),'double'); %utc offset
            TIME(i101,5)  = typecast(frame(hl+(29:32)),'uint32'); %UTC year
            TIME(i101,6)  = frame(hl+33);                         %UTC month
            TIME(i101,7)  = frame(hl+34);                         %UTC day
            TIME(i101,8)  = frame(hl+35);                         %UTC hour
            TIME(i101,9)  = frame(hl+36);                         %UTC minute
            TIME(i101,10) = typecast(frame(hl+(37:40)),'uint32'); %UTC ms
            TIME(i101,11) = typecast(frame(hl+(41:44)),'uint32'); %UTC status
            i101 = i101 + 1;
        case 140 %RANGECMP,P593
            svN = double(typecast(frame(hl+(1:4)),'uint32')); %number of SVs
            RANGECMP{i140,1} = svN;
%             RANGECMP{i140,2} = zeros(svN,10);
%             for m=1:svN
%                 record = frame(hl+4+24*(m-1)+(1:24)); %一个记录(uint8)
%                 recordBit = reshape(dec2bin(record,8)',1,[]); %将其转为01字符转
%                 RANGECMP{i140,2}(m,1) = twosComp2dec(recordBit(33:60))/256;
%             end
            i140 = i140 + 1;
        case 243 %PSRXYZ,P572
            PSRXYZ(i243,1)  = typecast(frame(hl+(1:4)),'uint32');     %P_solState
            PSRXYZ(i243,2)  = typecast(frame(hl+(5:8)),'uint32');     %posType
            PSRXYZ(i243,3)  = typecast(frame(hl+(9:16)),'double');    %X
            PSRXYZ(i243,4)  = typecast(frame(hl+(17:24)),'double');   %Y
            PSRXYZ(i243,5)  = typecast(frame(hl+(25:32)),'double');   %Z
            PSRXYZ(i243,6)  = typecast(frame(hl+(33:36)),'single');   %X sigma
            PSRXYZ(i243,7)  = typecast(frame(hl+(37:40)),'single');   %Y sigma
            PSRXYZ(i243,8)  = typecast(frame(hl+(41:44)),'single');   %Z sigma
            PSRXYZ(i243,9)  = typecast(frame(hl+(45:48)),'uint32');   %V_solState
            PSRXYZ(i243,10) = typecast(frame(hl+(49:52)),'uint32');   %velType
            PSRXYZ(i243,11) = typecast(frame(hl+(53:60)),'double');   %Vx
            PSRXYZ(i243,12) = typecast(frame(hl+(61:68)),'double');   %Vy
            PSRXYZ(i243,13) = typecast(frame(hl+(69:76)),'double');   %Vz
            PSRXYZ(i243,14) = typecast(frame(hl+(77:80)),'single');   %Vx sigma
            PSRXYZ(i243,15) = typecast(frame(hl+(81:84)),'single');   %Vy sigma
            PSRXYZ(i243,16) = typecast(frame(hl+(85:88)),'single');   %Vz sigma
            PSRXYZ(i243,17) = typecast(frame(hl+(93:96)),'single');   %V_latecy
            PSRXYZ(i243,18) = typecast(frame(hl+(97:100)),'single');  %diff age
            PSRXYZ(i243,19) = typecast(frame(hl+(101:104)),'single'); %sol age
            PSRXYZ(i243,20) = frame(hl+105);                          %trackSVs
            PSRXYZ(i243,21) = frame(hl+106);                          %solSVs
            PSRXYZ(i243,22) = frame(hl+110);                          %ext sol state
            PSRXYZ(i243,23) = frame(hl+111);                          %Galileo and BeiDou sig mask
            PSRXYZ(i243,24) = frame(hl+112);                          %GPS and GLONASS sig mask
            i243 = i243 + 1;
        case 971 %HEADING,P487
            HEADING(i971,1)  = typecast(frame(hl+(1:4)),'uint32');   %solState
            HEADING(i971,2)  = typecast(frame(hl+(5:8)),'uint32');   %posType
            HEADING(i971,3)  = typecast(frame(hl+(9:12)),'single');  %length
            HEADING(i971,4)  = typecast(frame(hl+(13:16)),'single'); %heading
            HEADING(i971,5)  = typecast(frame(hl+(17:20)),'single'); %pitch
            HEADING(i971,6)  = typecast(frame(hl+(25:28)),'single'); %heading sigma
            HEADING(i971,7)  = typecast(frame(hl+(29:32)),'single'); %pitch sigma
            HEADING(i971,8)  = frame(hl+37);                         %trackSVs
            HEADING(i971,9)  = frame(hl+38);                         %solSVs
            HEADING(i971,10) = frame(hl+39);                         %obsSVs
            HEADING(i971,11) = frame(hl+40);                         %multiSVs
            HEADING(i971,12) = frame(hl+41);                         %solSource
            HEADING(i971,13) = frame(hl+42);                         %ext sol state
            HEADING(i971,14) = frame(hl+43);                         %Galileo and BeiDou sig mask
            HEADING(i971,15) = frame(hl+44);                         %GPS and GLONASS sig mask
            i971 = i971 + 1;
    end
    %---------------------------------------------------------------------%
    k = k + hl+ml+4;
end

%% 整理成表格
BESTPOS = table(BESTPOS(:,1),BESTPOS(:,2),BESTPOS(:,3),BESTPOS(:,4),BESTPOS(:,5),...
                BESTPOS(:,6),BESTPOS(:,7),BESTPOS(:,8),BESTPOS(:,9),BESTPOS(:,10),...
                BESTPOS(:,11),BESTPOS(:,12),BESTPOS(:,13),BESTPOS(:,14),BESTPOS(:,15),...
                BESTPOS(:,16),BESTPOS(:,17),BESTPOS(:,18),BESTPOS(:,19));
BESTPOS.Properties.VariableNames = ...
                {'solState','posType','lat','lon','h','undulation',...
                 'datumID','latSigma','lonSigma','hSigma','diffAge','solAge',...
                 'trackSVs','solSVs','solL1SVs','solMultiSVs','extSolState',...
                 'Gal&BeiDouMask','Gps&GloMask'};

PSRXYZ = table(PSRXYZ(:,1),PSRXYZ(:,2),PSRXYZ(:,3),PSRXYZ(:,4),PSRXYZ(:,5),...
               PSRXYZ(:,6),PSRXYZ(:,7),PSRXYZ(:,8),PSRXYZ(:,9),PSRXYZ(:,10),...
               PSRXYZ(:,11),PSRXYZ(:,12),PSRXYZ(:,13),PSRXYZ(:,14),PSRXYZ(:,15),...
               PSRXYZ(:,16),PSRXYZ(:,17),PSRXYZ(:,18),PSRXYZ(:,19),PSRXYZ(:,20),...
               PSRXYZ(:,21),PSRXYZ(:,22),PSRXYZ(:,23),PSRXYZ(:,24));
PSRXYZ.Properties.VariableNames = ...
                {'P_solState','posType','X','Y','Z','Xsigma','Ysigma','Zsigma',...
                 'V_solState','velType','Vx','Vy','Vz','Vxsigma','Vysigma','Vzsigma',...
                 'V_latecy','diffAge','solAge','trackSVs','solSVs','extSolState',...
                 'Gal&BeiDouMask','Gps&GloMask'};

TIME = table(TIME(:,1),TIME(:,2),TIME(:,3),TIME(:,4),TIME(:,5),TIME(:,6),...
             TIME(:,7),TIME(:,8),TIME(:,9),TIME(:,10),TIME(:,11));
TIME.Properties.VariableNames = ...
                {'clockStatus','offset','offsetSigma','UTCoffset','UTCyear',...
                 'UTCmonth','UTCday','UTChour','UTCmin','UTCms','UTCstatus'};

HEADING = table(HEADING(:,1),HEADING(:,2),HEADING(:,3),HEADING(:,4),HEADING(:,5),...
                HEADING(:,6),HEADING(:,7),HEADING(:,8),HEADING(:,9),HEADING(:,10),...
                HEADING(:,11),HEADING(:,12),HEADING(:,13),HEADING(:,14),HEADING(:,15));
HEADING.Properties.VariableNames = ...
                {'solState','posType','length','heading','pitch','headingSigma','pitchSigma',...
                 'trackSVs','solSVs','obsSVs','multiSVs','solSource','extSolState',...
                 'Gal&BeiDouMask','Gps&GloMask'};