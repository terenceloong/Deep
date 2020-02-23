function ephe = read_B303(filename)
% 读RINEX 3.03 BDS星历文件
% 文件后缀系统标识必须是b/B

%% 检查文件后缀
if ~contains('bB',filename(end))
    error('File error! File suffix must be .yyb/.yyB!')
end

%% 打开文件
fileID = fopen(filename);

%% 检查文件版本
tline = fgetl(fileID);
if ~strcmp(tline(6:9),'3.03')
    fclose(fileID);
    error('Version error! RINEX version must be 3.03')
end

%% 处理文件头部分
fseek(fileID, 0, 'bof'); %跳到文件开始
while 1
    tline = fgetl(fileID);
    label = strtrim(tline(61:end)); %头标签
    switch label
        case 'RINEX VERSION / TYPE'
            ephe.version = strtrim(tline(6:9)); %RINEX版本
            ephe.type = tline(21); %文件类型
            ephe.system = tline(41); %卫星系统
        case 'PGM / RUN BY / DATE'
        case 'COMMENT'
        case 'IONOSPHERIC CORR'
        case 'TIME SYSTEM CORR'
        case 'LEAP SECONDS'
            ephe.leapSecond = sscanf(tline(1:6),'%d'); %跳秒
        case 'END OF HEADER'
            break
    end
end
dataPos = ftell(fileID); %数据开始位置

%% 统计数据数量
SVtable = zeros(1,63); %卫星统计表
SVn = length(SVtable); %卫星总数

while 1 %扫描数据部分
    tline = fgetl(fileID);
    if tline==-1 %读到文件尾tline返回-1
        break
    end
    if tline(1)~=' ' %星历首行
        PRN = sscanf(tline(2:3),'%d');
        SVtable(PRN) = SVtable(PRN) + 1;
    end
end

%% 构造星历存储结构体
epheStruct = struct('week',0,'TOW',0,'AODC',0,'AODE',0, ...
                    'toc',0,'af0',0,'af1',0,'af2',0,'TGD1',0,'TGD2',0, ...
                    'toe',0,'sqa',0,'e',0,'dn',0,'M0',0, ...
                    'omega',0,'Omega0',0,'Omega_dot',0, ...
                    'i0',0,'i_dot',0,'Cus',0,'Cuc',0, ...
                    'Crs',0,'Crc',0,'Cis',0,'Cic',0, ...
                    'accuracy',0,'health',0);

%% 创建存储空间
ephe.sv = cell(SVn,1);
for k=1:SVn
    if SVtable(k)~=0
        ephe.sv{k} = repmat(epheStruct,SVtable(k),1);
    else
        ephe.sv{k} = [];
    end
end

%% 读星历数据
fseek(fileID, dataPos, 'bof'); %跳到数据开始位置
ki = zeros(1,SVn); %指向当前记录行,每颗卫星由于数据量不同,需要为其独立分配值
day0 = datenum(2006,1,1); %BDS时间起点

while 1
    tline = fgetl(fileID); %第1行
    if tline==-1 %读到文件尾tline返回-1
        break
    end
    PRN = sscanf(tline(2:3),'%d');
    ki(PRN) = ki(PRN) + 1;
    k = ki(PRN); %当前记录行
    c = sscanf(tline(5:23),'%d')';
    day = datenum(c(1),c(2),c(3)) - day0;
    second = (day-floor(day/7)*7)*86400 + c(4)*3600 + c(5)*60 + c(6);
    ephe.sv{PRN}(k).toc = second;
    ephe.sv{PRN}(k).af0 = eval(tline(24:42)); %s
    ephe.sv{PRN}(k).af1 = eval(tline(43:61)); %s/s
    ephe.sv{PRN}(k).af2 = eval(tline(62:80)); %s/s^2
    tline = fgetl(fileID); %第2行
    ephe.sv{PRN}(k).AODE = eval(tline(5:23));
    ephe.sv{PRN}(k).Crs = eval(tline(24:42)); %m
    ephe.sv{PRN}(k).dn = eval(tline(43:61)); %rad/s
    ephe.sv{PRN}(k).M0 = eval(tline(62:80)); %rad
    tline = fgetl(fileID); %第3行
    ephe.sv{PRN}(k).Cuc = eval(tline(5:23)); %rad
    ephe.sv{PRN}(k).e = eval(tline(24:42));
    ephe.sv{PRN}(k).Cus = eval(tline(43:61)); %rad
    ephe.sv{PRN}(k).sqa = eval(tline(62:80)); %m^0.5
    tline = fgetl(fileID); %第4行
    ephe.sv{PRN}(k).toe = eval(tline(5:23));
    ephe.sv{PRN}(k).Cic = eval(tline(24:42)); %rad
    ephe.sv{PRN}(k).Omega0 = eval(tline(43:61)); %rad
    ephe.sv{PRN}(k).Cis = eval(tline(62:80)); %rad
    tline = fgetl(fileID); %第5行
    ephe.sv{PRN}(k).i0 = eval(tline(5:23)); %rad
    ephe.sv{PRN}(k).Crc = eval(tline(24:42)); %m
    ephe.sv{PRN}(k).omega = eval(tline(43:61)); %rad
    ephe.sv{PRN}(k).Omega_dot = eval(tline(62:80)); %rad/s
    tline = fgetl(fileID); %第6行
    ephe.sv{PRN}(k).i_dot = eval(tline(5:23)); %rad/s
    ephe.sv{PRN}(k).week = eval(tline(43:61));
    tline = fgetl(fileID); %第7行
    ephe.sv{PRN}(k).accuracy = eval(tline(5:23)); %m
    ephe.sv{PRN}(k).health = eval(tline(24:42));
    ephe.sv{PRN}(k).TGD1 = eval(tline(43:61)); %s
    ephe.sv{PRN}(k).TGD2 = eval(tline(62:80)); %s
    tline = fgetl(fileID); %第8行
    ephe.sv{PRN}(k).TOW = eval(tline(5:23)); %s
    ephe.sv{PRN}(k).AODC = eval(tline(24:42));
end

%% 关闭文件
fclose(fileID);

end