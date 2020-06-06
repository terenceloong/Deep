function acqResult = acq(obj, dataI, dataQ)
% 捕获卫星信号
% acqResult:捕获结果,[码相位,载波频率,峰值比值],无结果为[]
% dataI,dataQ:原始数据,行向量

fs = obj.sampleFreq; %采样频率,Hz
N = obj.acqN; %捕获采样点数
M = obj.acqM; %搜索频率个数

% 取连续两个复基带数据,因为可能存在导航电文的翻转导致相关峰变小
signal1 =     dataI(1:N) + dataQ(1:N)*1i;
signal2 = dataI(N+1:end) + dataQ(N+1:end)*1i;

% 搜索结果存储空间
n = fs*0.001; %一个C/A码周期采样点数
result1 = zeros(M,n); %搜索结果表格,行是载波频率,列是码相位
result2 = zeros(M,n);

% 搜索每个频率
t = -2i*pi/fs * (0:N-1);
for k=1:M
    carrier = exp(obj.acqFreq(k)*t); %本地复载波,负频率
    x = signal1.*carrier;
    X = fft(x);
    Y = conj(X).*obj.CODE;
    y = abs(ifft(Y));
    result1(k,:) = y(1:n); %只取一个C/A码周期的数,后面的都是重复的
    x = signal2.*carrier;
    X = fft(x);
    Y = conj(X).*obj.CODE;
    y = abs(ifft(Y));
    result2(k,:) = y(1:n);
end

% 选取值大的那组数据
[corrValue1, codePhase1] = max(result1,[],2); %按行找最大值,结果为列
[corrValue2, codePhase2] = max(result2,[],2);
if max(corrValue1)>max(corrValue2)
    corrValue = corrValue1;
    codePhase = codePhase1;
else
    corrValue = corrValue2;
    codePhase = codePhase2;
end

% 寻找相关峰
[peak1, index] = max(corrValue); %最大峰
corrValue(mod(index+(-3:3)-1,M)+1) = 0; %排除掉最大相关峰周围的点
peak2 = max(corrValue); %第二大峰

% 捕获结果
peakRatio = peak1 / peak2; %最高峰与第二大峰的比值
if peakRatio>obj.acqThreshold
    acqResult = [codePhase(index), obj.acqFreq(index), peakRatio];
else
    acqResult = [];
end

end