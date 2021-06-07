% 解析MTi数据

clear
clc

%% 读文件
% [file, path] = uigetfile('C:\Users\longt\Desktop\sscom\*.DAT');
% if ~ischar(file)
%     error('File error!')
% end
% fileID = fopen([path,file]);

fileID = fopen('MTi710.DAT');
data = fread(fileID, Inf, 'uint8=>uint8');
fclose(fileID);

%% 统计帧个数
n = length(data); %字节数
k = 1; %字节指针
pn = 0; %帧个数
while 1
    if k+3>n
        break
    end
    if data(k)==250 && data(k+1)==255 && data(k+2)==54 %54表明是数据帧
        m = double(data(k+3)); %一帧的数据长度
        if m==255
            error('externed length message')
        end
        if k+4+m>n
            break
        end
        packet = data(k:k+m+4); %一帧数据
        if mod(sum(double(packet(2:end))),256) %校验
            error('checksum error')
        end
        pn = pn+1; %帧计数加1
        k = k+m+5; %指向下一帧首字节
    else
        k = k+1;
    end
end

%% 读数据
packetCnt = NaN(pn,1);
sampleTime = NaN(pn,1); %10k时钟
UTC = NaN(pn,8);
imu = NaN(pn,6);
angle = NaN(pn,3); %姿态角
temp = NaN(pn,1); %温度
GNSS = NaN(pn,34); %卫星导航输出
i = 1; %存数据的位置
k = 1; %字节指针
while 1
    if k+3>n
        break
    end
    if data(k)==250 && data(k+1)==255 && data(k+2)==54 %54表明是数据帧
        m = double(data(k+3)); %一帧的数据长度
        if k+4+m>n
            break
        end
        dk = 1;
        while dk<m
            id = data(k+3+dk+[0,1]); %数据标识,两位
            dm = double(data(k+3+dk+2)); %数据长度
            bytes = data(k+3+dk+2+(1:dm))';
            if id(1)==16 && id(2)==32 %0x1020,包计数 (5)
                packetCnt(i) = swapbytes(typecast(bytes,'uint16'));
            elseif id(1)==16 && id(2)==96 %0x1060,采样时间 (7)
                sampleTime(i) = swapbytes(typecast(bytes,'uint32'));
            elseif id(1)==64 && id(2)==32 %0x4020,加速度 (15)
                imu(i,4:6) = swapbytes(typecast(bytes,'single'));
            elseif id(1)==128 && id(2)==32 %0x8020,角速度 (15)
                imu(i,1:3) = swapbytes(typecast(bytes,'single'));
            elseif id(1)==32 && id(2)==48 %0x2030,姿态角 (15)
                angle(i,:) = swapbytes(typecast(bytes,'single'));
            elseif id(1)==8 && id(2)==16 %0x0810,温度 (7)
                temp(i) = swapbytes(typecast(bytes,'single'));
            elseif id(1)==16 && id(2)==16 %0x1010,UTC (15)
                UTC(i,1) = swapbytes(typecast(bytes(1:4),'uint32'));
                UTC(i,2) = swapbytes(typecast(bytes(5:6),'uint16'));
                UTC(i,3:8) = bytes(7:12);
            elseif id(1)==112 && id(2)==16 %0x7010,GNSS (97)
                GNSS(i,1) = swapbytes(typecast(bytes(1:4),'uint32')); %GPS time of week, ms
                GNSS(i,2) = swapbytes(typecast(bytes(5:6),'uint16')); %year
                GNSS(i,3) = bytes(7); %month
                GNSS(i,4) = bytes(8); %day
                GNSS(i,5) = bytes(9); %hour
                GNSS(i,6) = bytes(10); %min
                GNSS(i,7) = bytes(11); %sec
                GNSS(i,8) = bytes(12); %valid
                GNSS(i,9) = swapbytes(typecast(bytes(13:16),'uint32')); %时间精度, ns
                GNSS(i,10) = swapbytes(typecast(bytes(17:20),'int32')); %nano sec
                GNSS(i,11) = bytes(21); %fixtype
                GNSS(i,12) = bytes(22); %flags
                GNSS(i,13) = bytes(23); %numSV
                GNSS(i,14) = double(swapbytes(typecast(bytes(25:28),'int32'))) * 1e-7; %lon
                GNSS(i,15) = double(swapbytes(typecast(bytes(29:32),'int32'))) * 1e-7; %lat
                GNSS(i,16) = double(swapbytes(typecast(bytes(33:36),'int32'))) * 1e-3; %h
                GNSS(i,17) = double(swapbytes(typecast(bytes(37:40),'int32'))) * 1e-3; %hMSL
                GNSS(i,18) = double(swapbytes(typecast(bytes(41:44),'uint32'))) * 1e-3; %水平精度
                GNSS(i,19) = double(swapbytes(typecast(bytes(45:48),'uint32'))) * 1e-3; %垂直精度
                GNSS(i,20) = double(swapbytes(typecast(bytes(49:52),'int32'))) * 1e-3; %vn
                GNSS(i,21) = double(swapbytes(typecast(bytes(53:56),'int32'))) * 1e-3; %ve
                GNSS(i,22) = double(swapbytes(typecast(bytes(57:60),'int32'))) * 1e-3; %vd
                GNSS(i,23) = double(swapbytes(typecast(bytes(61:64),'int32'))) * 1e-3; %地面速度
                GNSS(i,24) = double(swapbytes(typecast(bytes(65:68),'int32'))) * 1e-5; %速度航向
                GNSS(i,25) = double(swapbytes(typecast(bytes(69:72),'uint32'))) * 1e-3; %速度精度
                GNSS(i,26) = double(swapbytes(typecast(bytes(73:76),'uint32'))) * 1e-5; %航向精度
                GNSS(i,27) = double(swapbytes(typecast(bytes(77:80),'int32'))) * 1e-5; %载体航向
                GNSS(i,28) = swapbytes(typecast(bytes(81:82),'uint16')) * 0.01; %GDOP
                GNSS(i,29) = swapbytes(typecast(bytes(83:84),'uint16')) * 0.01; %PDOP
                GNSS(i,30) = swapbytes(typecast(bytes(85:86),'uint16')) * 0.01; %TDOP
                GNSS(i,31) = swapbytes(typecast(bytes(87:88),'uint16')) * 0.01; %VDOP
                GNSS(i,32) = swapbytes(typecast(bytes(89:90),'uint16')) * 0.01; %HDOP
                GNSS(i,33) = swapbytes(typecast(bytes(91:92),'uint16')) * 0.01; %NDOP
                GNSS(i,34) = swapbytes(typecast(bytes(93:94),'uint16')) * 0.01; %EDOP
            end
            dk = dk+3+dm;
        end
        i = i+1; %指向下一存储位置
        k = k+m+5;
    else
        k = k+1;
    end
end

%% 数据整理
imu(:,1:3) = imu(:,1:3) /pi*180; %角速度变成deg/s
imu(:,[2,3,5,6]) = -imu(:,[2,3,5,6]); %体系转为前右下
index = ~isnan(imu(:,1));
imu = [sampleTime(index), imu(index,:)];

angle = angle(:,[3,2,1]); %[yaw,pitch,roll]
index = ~isnan(angle(:,1));
angle = [sampleTime(index), angle(index,:)];

index = ~isnan(temp);
temp = [sampleTime(index), temp(index)];

index = ~isnan(GNSS(:,1));
GNSS = [sampleTime(index), GNSS(index,:)];