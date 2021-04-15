% 解析MTi数据

clear
clc

%% 读文件
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
sampleTime = NaN(pn,1);
UTC = NaN(pn,8);
imu = NaN(pn,6);
angle = NaN(pn,3);
temp = NaN(pn,1);
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
            if id(1)==16 && id(2)==32 %0x1020,包计数
                packetCnt(i) = swapbytes(typecast(bytes,'uint16'));
            elseif id(1)==16 && id(2)==96 %0x1060,采样时间
                sampleTime(i) = swapbytes(typecast(bytes,'uint32'));
            elseif id(1)==64 && id(2)==32 %0x4020,加速度
                imu(i,4:6) = swapbytes(typecast(bytes,'single'));
            elseif id(1)==128 && id(2)==32 %0x8020,角速度
                imu(i,1:3) = swapbytes(typecast(bytes,'single'));
            elseif id(1)==32 && id(2)==48 %0x2030,姿态角
                angle(i,:) = swapbytes(typecast(bytes,'single'));
            elseif id(1)==8 && id(2)==16 %0x0810,温度
                temp(i) = swapbytes(typecast(bytes,'single'));
            elseif id(1)==16 && id(2)==16 %0x1010,UTC
                UTC(i,1) = swapbytes(typecast(bytes(1:4),'uint32'));
                UTC(i,2) = swapbytes(typecast(bytes(5:6),'uint16'));
                UTC(i,3:8) = bytes(7:12);
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