function clean_storage(obj)
% 清理数据存储

% 清理通道内多余的存储空间
for k=1:obj.chN
    obj.channels(k).clean_storage;
end

% 获取所有场名,元胞数组
fields = fieldnames(obj.storage);

% 清理多余的接收机输出存储空间
n = obj.ns + 1;
for k=1:length(fields)
    if size(obj.storage.(fields{k}),3)==1 %二维存储空间
        obj.storage.(fields{k})(n:end,:) = [];
    else %三维存储空间
        obj.storage.(fields{k})(:,:,n:end) = [];
    end
end

% 整理卫星测量信息,元胞数组,每个通道一个矩阵
n = size(obj.storage.satmeas,3); %存储元素个数
m = size(obj.storage.satmeas,2); %列数
if n>0
    satmeas = cell(obj.chN,1);
    for k=1:obj.chN
        satmeas{k} = reshape(obj.storage.satmeas(k,:,:),m,n)';
    end
    obj.storage.satmeas = satmeas;
end

end