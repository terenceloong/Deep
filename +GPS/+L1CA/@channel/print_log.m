function print_log(obj)
% 打印通道日志

fprintf('GPS %d\n', obj.PRN); %卫星编号,使用\r\n会多一个空行
n = length(obj.log); %通道日志行数
if n>0 %如果日志有内容,逐行打印
    for k=1:n
        disp(obj.log(k))
    end
end
disp(' ') %结尾加一个空行

end