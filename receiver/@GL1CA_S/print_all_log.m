function print_all_log(obj)
% 打印所有通道日志

disp('<----------------------------------------------------->')
for k=1:obj.chN
    obj.channels(k).print_log;
end

end