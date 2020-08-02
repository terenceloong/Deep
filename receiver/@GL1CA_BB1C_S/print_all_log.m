function print_all_log(obj)
% 打印所有通道日志

if obj.GPSflag==1
    disp('<----GPS---------------------------------------------->')
    for k=1:obj.GPS.chN
        obj.GPS.channels(k).print_log;
    end
end

if obj.BDSflag==1
    disp('<----BDS---------------------------------------------->')
    for k=1:obj.BDS.chN
        obj.BDS.channels(k).print_log;
    end
end

end