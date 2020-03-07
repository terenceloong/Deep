function acqResult = acquisition(filename, fs, sampleOffset, acqConf)
% 所有GPS卫星L1 C/A信号的捕获,画图
% filename:文件名
% fs:采样频率,Hz
% sampleOffset:抛弃前多少个采样点
% acqConf:捕获参数配置
% acqResult:捕获结果,[码相位,载波频率,峰值比值]
% 参考GPS.L1CA.channel.acq

N = fs/1000 * acqConf.time; %捕获采样点数
acqFreq = -acqConf.freqMax:(fs/N/2):acqConf.freqMax; %搜索频率范围
M = length(acqFreq); %搜索频率个数

% 读数据,取连续两个复基带数据
fileID = fopen(filename, 'r');
fseek(fileID, round(sampleOffset*4), 'bof');
if int64(ftell(fileID))~=int64(sampleOffset*4)
    error('Sample offset error!')
end
signal = double(fread(fileID, [2,N], 'int16'));
signal1 = signal(1,:) + signal(2,:)*1i; %复信号
signal = double(fread(fileID, [2,N], 'int16'));
signal2 = signal(1,:) + signal(2,:)*1i;
fclose(fileID);

% 搜索结果存储空间
n = fs*0.001; %一个C/A码周期采样点数
result1 = zeros(M,n); %搜索结果表格,行是载波频率,列是码相位
result2 = zeros(M,n);

% 画图格子
[Xg, Yg] = meshgrid(1:n, acqFreq);

% 捕获
acqResult = NaN(32,3);
codeIndex = mod(floor((0:N-1)*1.023e6/fs),1023) + 1; %C/A码采样的索引
t = -2i*pi * (0:N-1)/fs; %生成载波时用的时间序列,负频率,虚数单位
for PRN=1:32
    %----生成本地码的FFT
    CAcode = GPS.L1CA.codeGene(PRN);
    CODE = fft(CAcode(codeIndex));
    %----搜索每个频率
    for k=1:M
        carrier = exp(acqFreq(k)*t);
        x = signal1.*carrier;
        X = fft(x);
        Y = conj(X).*CODE;
        y = abs(ifft(Y));
        result1(k,:) = y(1:n); %只取一个C/A码周期的数,后面的都是重复的
        x = signal2.*carrier;
        X = fft(x);
        Y = conj(X).*CODE;
        y = abs(ifft(Y));
        result2(k,:) = y(1:n);
    end
    %----选取值大的那组数据
    [corrValue1, codePhase1] = max(result1,[],2); %按行找最大值,结果为列
    [corrValue2, codePhase2] = max(result2,[],2);
    if max(corrValue1)>max(corrValue2)
        corrValue = corrValue1;
        codePhase = codePhase1;
        result = result1; %用来画图
    else
        corrValue = corrValue2;
        codePhase = codePhase2;
        result = result2;
    end
    %----寻找相关峰
    [peak1, index] = max(corrValue); %最大峰
    corrValue(mod(index+(-3:3)-1,M)+1) = 0; %排除掉最大相关峰周围的点
    peak2 = max(corrValue); %第二大峰
    %----输出捕获结果,画图
    peakRatio = peak1 / peak2; %最高峰与第二大峰的比值
    if peakRatio>acqConf.threshold
        acqResult(PRN,:) = [codePhase(index), acqFreq(index), peakRatio];
        figure
        surf(Xg,Yg,result)
        title(['PRN ',num2str(PRN),', ',num2str(peakRatio)])
    end
end

end