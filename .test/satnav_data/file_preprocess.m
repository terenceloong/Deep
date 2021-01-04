% 文件预处理,生成time,rho,rhodot序列

fileID = fopen('ReceivedTofile-COM11-2020_12_31_17-12-35.DAT');

% 统计数据行数
N = 0;
while ~feof(fileID)
    tline = fgetl(fileID);
    if strcmp(tline(1:4),'time')
        N = N+1;
    end
end
fseek(fileID, 0, 'bof'); %移到文件开头

time = zeros(N,3);
rho = NaN(N,32);
rhodot = NaN(N,32);

% 记录卫星数据
k = 0;
while ~feof(fileID)
    tline = fgetl(fileID);
    if strcmp(tline(1:4),'time')
        k = k+1;
        data = sscanf(tline, 'time: %d %d %f')';
        time(k,:) = data;
    end
    if strcmp(tline(1:2),'m:')
        data = sscanf(tline, 'm:%d %d %f %f %f %d %f')';
        rho(k,data(2)) = data(4);
        rhodot(k,data(2)) = -data(5);
    end
end

fclose(fileID);