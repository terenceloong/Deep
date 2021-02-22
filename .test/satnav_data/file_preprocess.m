% 文件预处理,生成time,rho,rhodot序列

clear
clc

% fileID = fopen('ReceivedTofile-COM11-2020_12_31_17-12-35.DAT'); %只有伪距伪距率,多普勒反
% fileID = fopen('ReceivedTofile-COM11-2021_2_2_17-46-38.DAT'); %带卫星解算,多普勒反
% fileID = fopen('C:\Users\longt\Desktop\sscom\ReceivedTofile-COM11-2021_2_3_9-20-49.DAT');
% fileID = fopen('C:\Users\longt\Desktop\sscom\ReceivedTofile-COM11-2021_2_9_17-32-55.DAT'); %调试导航滤波器,多普勒正
% fileID = fopen('C:\Users\longt\Desktop\sscom\ReceivedTofile-COM11-2021_2_19_10-22-38.DAT');
% fileID = fopen('C:\Users\longt\Desktop\sscom\ReceivedTofile-COM11-2021_2_19_10-39-48.DAT');ReceivedTofile-COM11-2021_2_19_11-53-02
% fileID = fopen('C:\Users\longt\Desktop\sscom\ReceivedTofile-COM11-2021_2_19_11-53-02.DAT');
% fileID = fopen('C:\Users\longt\Desktop\sscom\ReceivedTofile-COM11-2021_2_20_10-00-44.DAT');
fileID = fopen('C:\Users\longt\Desktop\sscom\ReceivedTofile-COM11-2021_2_20_11-22-59.DAT'); %矢量,好

% 统计数据行数
N = 0;
while ~feof(fileID)
    tline = fgetl(fileID);
    if strcmp(tline(1:4),'time')
        N = N+1;
    end
end
fseek(fileID, 0, 'bof'); %移到文件开头

% 测量的伪距伪距率
time = zeros(N,3);
rho = NaN(N,32);
rhodot = NaN(N,32);
codeFreq = NaN(N,32);

% 在线解算结果
pos = NaN(N,3);
vel = NaN(N,3);
clk = NaN(N,2);

% 在线滤波结果
posF = NaN(N,3);
velF = NaN(N,3);
accF = NaN(N,3);
clkF = NaN(N,2);

% 记录卫星数据
k = 0;
while ~feof(fileID)
    tline = fgetl(fileID);
    %----接收机时间
    if strcmp(tline(1:4),'time')
        k = k+1;
        data = sscanf(tline, 'time: %d %d %f')';
        time(k,:) = data;
    end
    %----伪距伪距率
    if strcmp(tline(1:2),'m:')
        data = sscanf(tline, 'm:%d %d %f %f %f %d %f')';
        rho(k,data(2)) = data(4);
%         rhodot(k,data(2)) = -data(5); %多普勒反
        rhodot(k,data(2)) = data(5); %多普勒正
        %------------------------------------------------------------------
%         data = sscanf(tline, 'm:%d %d %f %f %f %d %f %f')';
%         rho(k,data(2)) = data(4);
%         rhodot(k,data(2)) = data(5); %多普勒正
%         codeFreq(k,data(2)) = data(8);
    end
    %----在线卫星导航解算结果
    if strcmp(tline(1:4),'POS:')
        data = sscanf(tline, 'POS:%f %f %f')';
        pos(k,:) = data;
    end
    if strcmp(tline(1:4),'VEL:')
        data = sscanf(tline, 'VEL:%f %f %f')';
        vel(k,:) = data;
    end
    if strcmp(tline(1:6),'CLOCK:')
        data = sscanf(tline, 'CLOCK:%f %f')';
        clk(k,:) = data;
    end
    %----在线卫星导航解算结果
    if strcmp(tline(1:3),'Ps:')
        data = sscanf(tline, 'Ps:%f %f %f')';
        pos(k,:) = data;
    end
    if strcmp(tline(1:3),'Vs:')
        data = sscanf(tline, 'Vs:%f %f %f')';
        vel(k,:) = data;
    end
    if strcmp(tline(1:3),'Cs:')
        data = sscanf(tline, 'Cs:%f %f')';
        clk(k,:) = data;
    end
    %----在线滤波结果
    if strcmp(tline(1:3),'Pf:')
        data = sscanf(tline, 'Pf:%f %f %f')';
        posF(k,:) = data;
    end
    if strcmp(tline(1:3),'Vf:')
        data = sscanf(tline, 'Vf:%f %f %f')';
        velF(k,:) = data;
    end
    if strcmp(tline(1:3),'Af:')
        data = sscanf(tline, 'Af:%f %f %f')';
        accF(k,:) = data;
    end
    if strcmp(tline(1:3),'Cf:')
        data = sscanf(tline, 'Cf:%f %f')';
        clkF(k,:) = data;
    end
end

fclose(fileID);