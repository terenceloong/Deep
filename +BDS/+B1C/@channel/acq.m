function acqResult = acq(obj, dataI, dataQ)
% 捕获卫星信号
% acqResult:捕获结果,[码相位,载波频率,峰值比值],无结果为[]
% dataI,dataQ:原始数据,行向量

fs = obj.sampleFreq; %采样频率,Hz
N = obj.acqN; %捕获采样点数
M = obj.acqM; %搜索频率个数

% 数据转化为复数
signal = dataI + dataQ*1i;

% 搜索结果存储空间
n = fs*0.01; %一个伪码周期采样点数
result = zeros(M,n);

% 搜索每个频率
t = -2i*pi/fs * (0:N-1);
for k=1:M
    carrier = exp(obj.acqFreq(k)*t); %本地复载波,负频率
    x = signal.*carrier;
    X = fft(x);
    Y = conj(X).*obj.CODE;
    y = abs(ifft(Y));
    result(k,:) = y(1:n); %只取前n个
end

% 寻找相关峰
[corrValue, codePhase] = max(result,[],2); %按行找最大值,结果为列
[peak1, index] = max(corrValue); %最大峰
corrValue(mod(index+(-5:5)-1,M)+1) = 0; %排除掉最大相关峰周围的点
peak2 = max(corrValue); %第二大峰

% 捕获结果
peakRatio = peak1 / peak2; %最高峰与第二大峰的比值
if peakRatio>obj.acqThreshold
    acqResult = [codePhase(index), obj.acqFreq(index), peakRatio];
else
    acqResult = [];
end

end