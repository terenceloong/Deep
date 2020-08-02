function acqResult = acquisition(filename, fs, sampleOffset, acqConf)
% 所有北斗卫星B1C信号的捕获,画图
% filename:文件名
% fs:采样频率,Hz
% sampleOffset:抛弃前多少个采样点
% acqConf:捕获参数配置
% acqResult:捕获结果,[卫星号,码相位,载波频率]

%北斗三号播发B1C信号的卫星列表
svList = [19:30,32:46]; %共27颗

N = fs/100; %一个码周期(10ms)采样点数
Ns = 2*N; %一次捕获采样点数,需要两个码周期
acqFreq = -acqConf.freqMax:(fs/N/2):acqConf.freqMax; %搜索频率范围
M = length(acqFreq); %搜索频率个数

% 读数据,复数,20ms
fileID = fopen(filename, 'r');
fseek(fileID, round(sampleOffset*4), 'bof');
if int64(ftell(fileID))~=int64(sampleOffset*4)
    error('Sample offset error!')
end
signal = double(fread(fileID, [2,Ns], 'int16'));
signal = signal(1,:) + signal(2,:)*1i; %复信号
fclose(fileID);

% 搜索结果存储空间
result = zeros(M,N); %搜索结果表格,行是载波频率,列是码相位

% 捕获
acqResult = NaN(length(svList),2);
codeIndex = floor((0:N-1)*1.023e6*2/fs) + 1; %本地码采样的索引,因为加了子载波,相当于码频率乘2
t = -2i*pi * (0:Ns-1)/fs; %生成载波时用的时间序列,负频率,虚数单位
for PRN=svList
    %----生成包含子载波的本地码,计算FFT
%     B1Ccode = BDS.B1C.codeGene_data(PRN); %捕获数据通道
    B1Ccode = BDS.B1C.codeGene_pilot(PRN); %捕获导频通道
    B1Ccode = reshape([B1Ccode;-B1Ccode],10230*2,1)'; %加子载波,行向量
    codes = B1Ccode(codeIndex);
    code = [zeros(1,N), codes]; %前面补零
    CODE = fft(code);
    %----搜索每个频率
    for k=1:M
        carrier = exp(acqFreq(k)*t);
        x = signal.*carrier;
        X = fft(x);
        Y = conj(X).*CODE;
        y = abs(ifft(Y));
        result(k,:) = y(1:N); %只取前N个
    end
    %----寻找相关峰
    [corrValue, codePhase] = max(result,[],2); %按行找最大值,结果为列
    [peak1, index] = max(corrValue); %最大峰
    corrValue(mod(index+(-5:5)-1,M)+1) = 0; %排除掉最大相关峰周围的点
    peak2 = max(corrValue); %第二大峰
    %----输出 捕获结果,画图
    peakRatio = peak1 / peak2; %最高峰与第二大峰的比值
    if peakRatio>acqConf.threshold
        % 存捕获结果
        ki = find(svList==PRN,1);
        acqResult(ki,1) = codePhase(index); %码相位,额外加一个数可以模拟错误捕获码相位
        acqResult(ki,2) = acqFreq(index); %载波频率
        % 画图
        figure
        subplot(2,1,1) %码相位为横轴,放大可以看到副相关峰
        plot(result(index,:)) %result的行
        grid on
        xlabel('code phase')
        title(['PRN ',num2str(PRN),', ',num2str(peakRatio)])
        subplot(2,1,2) %载波频率为横轴
        plot(acqFreq, result(:,codePhase(index))') %result的列
        grid on
        xlabel('carrier frequency')
        drawnow
    end
end

acqResult = [svList', acqResult]; %第一列添加卫星编号

end