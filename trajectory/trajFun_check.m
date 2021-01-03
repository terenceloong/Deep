function trajFun_check(trajFun, name)
% 检查轨迹函数是否正确

[N, M] = size(trajFun); %轨迹函数维数
if M~=2 %列数必须为2
    error([name, ': Dimension error!'])
end

%----最后一个时间维数必须是1
if length(trajFun{end,1})~=1
    error([name, ': The last time must be a scalar!'])
end

%----初始时间必须是0
if trajFun{1,1}(1)~=0
    error([name, ': The initial time must be 0!'])
end

%----时间必须连续
for k=1:N-1
    if trajFun{k,1}(2)~=trajFun{k+1,1}(1)
        error([name, ': Time is discontinuous! k=', num2str(k)])
    end
end

%----数值必须连续
for k=1:N-1
    % 上个数值
    if isnumeric(trajFun{k,2}) %常数
        x0 = trajFun{k,2};
    else %函数
        fun = matlabFunction(trajFun{k,2}); %将符号函数转换成匿名函数
        x0 = fun(trajFun{k,1}(2));
    end
    % 当前数值
    if isnumeric(trajFun{k+1,2}) %常数
        x1 = trajFun{k+1,2};
    else %函数
        fun = matlabFunction(trajFun{k+1,2}); %将符号函数转换成匿名函数
        x1 = fun(trajFun{k+1,1}(1));
    end
    if abs(x0-x1)>1e-10
        error([name, ': Value is discontinuous! k=', num2str(k)])
    end
end

end