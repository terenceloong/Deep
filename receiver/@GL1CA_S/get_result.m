function get_result(obj)
% 获取接收机运行结果

% 统计跟踪过信号的通道索引和卫星编号
obj.result.trackedIndex = [];
obj.result.trackedPRN = [];
flag = zeros(1,obj.chN); %是否跟踪到信号标志
for k=1:obj.chN
    if obj.channels(k).ns>0
        flag(k) = 1;
    end
end
index = find(flag==1); %通道索引
obj.result.trackedIndex = index;
n = length(index);
obj.result.trackedPRN = cell(1,n); %卫星编号是字符串元胞数组
for k=1:n
    obj.result.trackedPRN{k} = sprintf('%d', obj.svList(index(k)));
end

% 统计有卫星测量的通道索引和卫星编号
obj.result.satmeasIndex = [];
obj.result.satmeasPRN = [];
if ~isempty(obj.storage.satmeas)
    flag = zeros(1,obj.chN); %是否有卫星测量标志
    for k=1:obj.chN
        if any(~isnan(obj.storage.satmeas{k}(:,1))) %不全是NaN
            flag(k) = 1;
        end
    end
    index = find(flag==1); %通道索引
    obj.result.satmeasIndex = index;
    n = length(index);
    obj.result.satmeasPRN = cell(1,n); %卫星编号是字符串元胞数组
    for k=1:n
        obj.result.satmeasPRN{k} = sprintf('%d', obj.svList(index(k)));
    end
end

% 统计可见卫星数量
obj.result.svnum = zeros(obj.ns,2,'uint8'); %第一列是强信号数量,第二列是强+弱信号数量
obj.result.svnum(:,1) = sum(obj.storage.svsel==2,2);
obj.result.svnum(:,2) = sum(obj.storage.svsel>=1,2);

end