function clean_storage(obj)
% 清理数据存储

% 自动识别所有场,参见help-Generate Field Names from Variables
fields = fieldnames(obj.storage); %获取所有场名,元胞数组
n = obj.ns + 1;
for k=1:length(fields)
    obj.storage.(fields{k})(n:end,:) = [];
end

end