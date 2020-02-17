function ephe = read_N2(filename)
% 读RINEX 2 GPS星历文件
% 文件后缀系统标识必须是n/N
% 因为文件中数据使用D作为10幂标识,使用eval处理,参考str2num

%% 检查文件后缀
if ~contains('nN',filename(end))
    error('File error! File suffix must be .yyn/.yyN!')
end

%% 打开文件
fileID = fopen(filename);

%% 检查文件版本
tline = fgetl(fileID);
if ~strcmp(tline(6:9),'2   ')
    fclose(fileID);
    error('Version error! RINEX version must be 2')
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
        case 'PGM / RUN BY / DATE'
            ephe.program = strtrim(tline(1:20)); %生成文件的程序
            ephe.runBy = strtrim(tline(21:40)); %生成文件程序的厂商
        case 'COMMENT' %存注释没什么意义
        case 'ION ALPHA'
            ephe.alpha = eval(['[',tline(3:50),']']); %电离层参数alpha,数中间要有空格
        case 'ION BETA'
            ephe.beta = eval(['[',tline(3:50),']']); %电离层参数beta
        case 'DELTA-UTC: A0,A1,T,W'
            ephe.deltaUTC = zeros(1,4);
            ephe.deltaUTC(1) = eval(tline(4:22)); %A0
            ephe.deltaUTC(2) = eval(tline(23:41)); %A1
            ephe.deltaUTC(3) = sscanf(tline(42:50),'%d'); %T
            ephe.deltaUTC(4) = sscanf(tline(51:59),'%d'); %W,week
        case 'LEAP SECONDS'
            ephe.leapSecond = sscanf(tline(1:6),'%d'); %跳秒
        case 'END OF HEADER'
            break
    end
end
dataPos = ftell(fileID); %数据开始位置

%% 统计数据数量
SVtable = zeros(1,32); %卫星统计表
SVn = length(SVtable); %卫星总数

% 扫描数据部分
while 1
    tline = fgetl(fileID);
    if tline==-1 %读到文件尾tline返回-1
        break
    end
    if tline(2)~=' ' %星历首行
        PRN = sscanf(tline(1:2),'%d');
        SVtable(PRN) = SVtable(PRN) + 1;
    end
end

%% 构造星历存储结构体
epheStruct = struct('week',0,'TOW',0,'IODC',0,'IODE',0, ...
                    'toc',0,'af0',0,'af1',0,'af2',0,'TGD',0, ...
                    'toe',0,'sqa',0,'e',0,'dn',0,'M0',0, ...
                    'omega',0,'Omega0',0,'Omega_dot',0, ...
                    'i0',0,'i_dot',0,'Cus',0,'Cuc',0, ...
                    'Crs',0,'Crc',0,'Cis',0,'Cic',0, ...
                    'accuracy',0,'health',0,'fit_interval',0, ...
                    'codes_on_L2',0,'L2_P_data_flag',0);

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
day0 = datenum(1980,1,6); %GPS时间起点

% 因为取的字符一定有数据,使用eval替代str2num
while 1
    tline = fgetl(fileID);
    if tline==-1 %读到文件尾tline返回-1
        break
    end
    PRN = sscanf(tline(1:2),'%d');
    ki(PRN) = ki(PRN) + 1;
    k = ki(PRN); %当前记录行
    c = sscanf(tline(3:22),'%d %d %d %d %d %f')';
    day = datenum(c(1)+2000,c(2),c(3)) - day0;
    second = (day-floor(day/7)*7)*86400 + c(4)*3600 + c(5)*60 + round(c(6));
    ephe.sv{PRN}(k).toc = second;
    ephe.sv{PRN}(k).af0 = eval(tline(23:41)); %s
    ephe.sv{PRN}(k).af1 = eval(tline(42:60)); %s/s
    ephe.sv{PRN}(k).af2 = eval(tline(61:79)); %s/s^2
    tline = fgetl(fileID);
    ephe.sv{PRN}(k).IODE = eval(tline(4:22));
    ephe.sv{PRN}(k).Crs = eval(tline(23:41)); %m
    ephe.sv{PRN}(k).dn = eval(tline(42:60)); %rad/s
    ephe.sv{PRN}(k).M0 = eval(tline(61:79)); %rad
    tline = fgetl(fileID);
    ephe.sv{PRN}(k).Cuc = eval(tline(4:22)); %rad
    ephe.sv{PRN}(k).e = eval(tline(23:41));
    ephe.sv{PRN}(k).Cus = eval(tline(42:60)); %rad
    ephe.sv{PRN}(k).sqa = eval(tline(61:79)); %m^0.5
    tline = fgetl(fileID);
    ephe.sv{PRN}(k).toe = eval(tline(4:22));
    ephe.sv{PRN}(k).Cic = eval(tline(23:41)); %rad
    ephe.sv{PRN}(k).Omega0 = eval(tline(42:60)); %rad
    ephe.sv{PRN}(k).Cis = eval(tline(61:79)); %rad
    tline = fgetl(fileID);
    ephe.sv{PRN}(k).i0 = eval(tline(4:22)); %rad
    ephe.sv{PRN}(k).Crc = eval(tline(23:41)); %m
    ephe.sv{PRN}(k).omega = eval(tline(42:60)); %rad
    ephe.sv{PRN}(k).Omega_dot = eval(tline(61:79)); %rad/s
    tline = fgetl(fileID);
    ephe.sv{PRN}(k).i_dot = eval(tline(4:22)); %rad/s
    ephe.sv{PRN}(k).codes_on_L2 = eval(tline(23:41));
    ephe.sv{PRN}(k).week = eval(tline(42:60));
    ephe.sv{PRN}(k).L2_P_data_flag = eval(tline(61:79));
    tline = fgetl(fileID);
    ephe.sv{PRN}(k).accuracy = eval(tline(4:22)); %m
    ephe.sv{PRN}(k).health = eval(tline(23:41));
    ephe.sv{PRN}(k).TGD = eval(tline(42:60)); %s
    ephe.sv{PRN}(k).IODC = eval(tline(61:79));
    tline = fgetl(fileID);
    ephe.sv{PRN}(k).TOW = eval(tline(4:22)); %s
    ephe.sv{PRN}(k).fit_interval = eval(tline(23:41));
end

%% 关闭文件
fclose(fileID);

end