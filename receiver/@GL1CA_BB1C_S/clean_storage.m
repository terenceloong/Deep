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

% 获取所有场名,元胞数组
fields = fieldnames(obj.storage);

% 清理多余的接收机输出存储空间
n = obj.ns + 1;
for k=1:length(fields)
    if ismatrix(obj.storage.(fields{k})) %二维存储空间
        obj.storage.(fields{k})(n:end,:) = [];
    else %三维存储空间
        obj.storage.(fields{k})(:,:,n:end) = [];
    end
end

end