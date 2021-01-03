function trajTable = trajFun_process(trajFun)
% 计算导数,符号函数转化成匿名函数,得到时间序列

trajTable = cell(1,4); %{time, N, value, diff}

N = size(trajFun,1); %行数
time = zeros(1,N); %时间序列
trajTable{3} = cell(N,1);
trajTable{4} = cell(N,1);

for k=1:N
    time(k) = trajFun{k,1}(end); %提取时间
    if isnumeric(trajFun{k,2}) %常数
        trajTable{4}{k} = 0; %常数的导数是0
        trajTable{3}{k} = trajFun{k,2};
    else %函数
        temp = diff(trajFun{k,2}); %符号函数求导
        if hasSymType(temp,'variable') %导数中含自变量
            trajTable{4}{k} = matlabFunction(temp); %符号函数转化为匿名函数
        else
            trajTable{4}{k} = double(temp); %将符号转化为数字
        end
        trajTable{3}{k} = matlabFunction(trajFun{k,2}); %符号函数转化为匿名函数
    end
end

trajTable{1} = [0, time(1:N-1)]; %前面补零,删最后一个
trajTable{2} = N;

end