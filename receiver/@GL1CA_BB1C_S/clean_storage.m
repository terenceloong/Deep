function clean_storage(obj)
% 清理数据存储

% 清理通道内多余的存储空间
if obj.GPSflag==1
    for k=1:obj.GPS.chN
        obj.GPS.channels(k).clean_storage;
    end
end
if obj.BDSflag
    for k=1:obj.BDS.chN
        obj.BDS.channels(k).clean_storage;
    end
end

end