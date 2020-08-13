function get_result(obj)
% 获取接收机运行结果

%% 统计跟踪过信号的通道索引和卫星编号
if obj.GPSflag==1
    obj.result.GPS.trackedIndex = []; %跟踪到的卫星通道索引
    obj.result.GPS.trackedPRN = []; %跟踪到的卫星编号字符串
    flag = zeros(1,obj.GPS.chN); %是否跟踪到信号标志
    for k=1:obj.GPS.chN
        if obj.GPS.channels(k).ns>0
            flag(k) = 1;
        end
    end
    index = find(flag==1); %通道索引
    obj.result.GPS.trackedIndex = index;
    n = length(index);
    obj.result.GPS.trackedPRN = cell(1,n); %卫星编号是字符串元胞数组
    for k=1:n
        obj.result.GPS.trackedPRN{k} = sprintf('%d', obj.GPS.svList(index(k)));
    end
end
if obj.BDSflag==1
    obj.result.BDS.trackedIndex = []; %跟踪到的卫星通道索引
    obj.result.BDS.trackedPRN = []; %跟踪到的卫星编号字符串
    flag = zeros(1,obj.BDS.chN); %是否跟踪到信号标志
    for k=1:obj.BDS.chN
        if obj.BDS.channels(k).ns>0
            flag(k) = 1;
        end
    end
    index = find(flag==1); %通道索引
    obj.result.BDS.trackedIndex = index;
    n = length(index);
    obj.result.BDS.trackedPRN = cell(1,n); %卫星编号是字符串元胞数组
    for k=1:n
        obj.result.BDS.trackedPRN{k} = sprintf('%d', obj.BDS.svList(index(k)));
    end
end

%% 统计可见星数量
obj.result.svnumGPS = zeros(obj.ns,2,'uint8'); %第一列是强信号数量,第二列是强+弱信号数量
obj.result.svnumBDS = zeros(obj.ns,2,'uint8');
obj.result.svnumALL = zeros(obj.ns,2,'uint8');
if obj.GPSflag==1
    obj.result.svnumGPS(:,1) = sum(obj.storage.qualGPS==2,2);
    obj.result.svnumGPS(:,2) = sum(obj.storage.qualGPS>=1,2);
end
if obj.BDSflag==1
    obj.result.svnumBDS(:,1) = sum(obj.storage.qualBDS==2,2);
    obj.result.svnumBDS(:,2) = sum(obj.storage.qualBDS>=1,2);
end
obj.result.svnumALL(:,1) = obj.result.svnumGPS(:,1) + obj.result.svnumBDS(:,1);
obj.result.svnumALL(:,2) = obj.result.svnumGPS(:,2) + obj.result.svnumBDS(:,2);

end