function dt = sample2dt(n, fs)
% 采样点数转化为时间增量(n必须大于等于0)
% n:采样点数
% fs:采样频率,Hz

dt = [0,0,0]; %[s,ms,us]

t = n / fs;
dt(1) = floor(t); %整秒部分
t = mod(t,1) * 1000;
dt(2) = floor(t); %毫秒部分
dt(3) = mod(t,1) * 1000; %微秒部分

% dt(1) = floor(n/fs);
% dt(2) = floor(rem(n,fs) * (1e3/fs));
% % (1e3/fs)表示一个采样点多少毫秒,rem(n,fs)表示不足1秒有多少个采样点
% dt(3) = rem(n,(fs/1e3)) * (1e6/fs);
% % (1e6/fs)表示一个采样点多少微秒,rem(n,(fs/1e3))表示不足1毫秒有多少个采样点

end