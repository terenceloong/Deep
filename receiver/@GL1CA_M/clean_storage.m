function clean_storage(obj)
% 清理数据存储

% 清理通道内多余的存储空间
for m=1:obj.anN
    for k=1:obj.chN
        obj.channels(k,m).clean_storage;
    end
end

% 获取所有场名,元胞数组
fields = fieldnames(obj.storage);

% 清理多余的接收机输出存储空间
n = obj.ns + 1;
for k=1:length(fields)
    if ismatrix(obj.storage.(fields{k})) %二维矩阵
        obj.storage.(fields{k})(n:end,:) = [];
    else %非二维矩阵
        obj.storage.(fields{k})(:,:,n:end,:) = [];
    end
end

% 整理卫星位置速度
n = size(obj.storage.satpv,3); %存储元素个数
if n>0
    satpv = cell(obj.chN,1);
    for k=1:obj.chN
        satpv{k} = reshape(obj.storage.satpv(k,:,:),6,n)';
    end
    obj.storage.satpv = satpv;
end

% 整理卫星测量信息,元胞数组,行是通道,列是天线
n = size(obj.storage.satmeas,3); %存储元素个数
j = size(obj.storage.satmeas,2); %列数
if n>0
    satmeas = cell(obj.chN,obj.anN);
    for m=1:obj.anN
        for k=1:obj.chN
            satmeas{k,m} = reshape(obj.storage.satmeas(k,:,:,m),j,n)';
        end
    end
    obj.storage.satmeas = satmeas;
end

% 整理选星
n = size(obj.storage.svsel,3); %存储元素个数
j = size(obj.storage.svsel,1); %行数
if n>0
    svsel = cell(1,obj.anN);
    for m=1:obj.anN
        svsel{m} = reshape(obj.storage.svsel(:,1,:,m),j,n)';
    end
    obj.storage.svsel = svsel;
end

end