function get_result(obj)
% 获取接收机运行结果

% 统计跟踪过信号的通道索引和卫星编号


% 统计有卫星测量的通道索引和卫星编号
obj.result.satmeasIndex = [];
obj.result.satmeasPRN = [];
if ~isempty(obj.storage.satmeas)
    flag = zeros(1,obj.chN); %是否计算过位置标志
    for k=1:obj.chN
        if sum(~isnan(obj.storage.satmeas{k}(:,1)))>0 %不全是NaN
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

end