% 文件预处理,生成time,rho,rhodot序列

clear
clc

[file, path] = uigetfile('C:\Users\longt\Desktop\sscom\*.DAT');
if ~ischar(file)
    error('File error!')
end
fileID = fopen([path,file]);

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
time = zeros(N,3); %时间序列
rho = NaN(N,32); %伪距
rhodot = NaN(N,32); %伪距率

% 其他信息
codeFreq = NaN(N,32);
carrFreq = NaN(N,32);
carrNco  = NaN(N,32);
carrAccS = NaN(N,32);
carrAccR = NaN(N,32);
carrAccE = NaN(N,32);
CN0 = NaN(N,32);

% 在线解算结果
pos = NaN(N,3);
vel = NaN(N,3);
clk = NaN(N,2);

% 在线滤波结果
posF = NaN(N,3);
velF = NaN(N,3);
accF = NaN(N,3);
clkF = NaN(N,2);
stdF = NaN(N,3);

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
        %----格式1
        data = sscanf(tline, 'm:%d %d %f %f %d %f %d %f %f %f %d')';
        PRN = data(2); %卫星号
        rho(k,PRN) = data(3);
        rhodot(k,PRN) = data(4);
        CN0(k,PRN) = data(6);
        carrFreq(k,PRN) = data(4);
        carrNco(k,PRN) = data(8);
        carrAccR(k,PRN) = data(9);
        carrAccE(k,PRN) = data(10);
        %----格式2
        % 其他数据格式
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