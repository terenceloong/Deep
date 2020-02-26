function ts = sec2smu(t)
% 以秒为单位的时间转化为[s,ms,us]数组

ts = [0,0,0]; %[s,ms,us]

ts(1) = floor(t); %整秒部分
t = mod(t,1) * 1000;
ts(2) = floor(t); %毫秒部分
ts(3) = mod(t,1) * 1000; %微秒部分

end