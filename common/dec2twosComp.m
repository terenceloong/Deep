function out = dec2twosComp(in, N)
% 十进制数转化为二进制数组,-1表示0,1表示1
% in:为整数
% N:输出位数

if in<0
    binStr = dec2bin(2^N+in, N); %01字符串
else
    binStr = dec2bin(in, N);
end

out = ones(1,N);
out(binStr=='0') = -1; %对0的位置写-1

end