function plot_I_P_flag(obj)
% 画I_P图,带比特开始标志

PRN_str = ['GPS ',sprintf('%d',obj.PRN)];
figure('Position', screenBlock(1000,300,0.5,0.5), 'Name',PRN_str);
axes('Position', [0.05, 0.15, 0.9, 0.75]);
t = obj.storage.dataIndex/obj.sampleFreq;
plot(t, double(obj.storage.I_Q(:,1)))
set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
hold on

% 标记寻找帧头阶段(粉色),该阶段的结尾一定是[1,0,0,0,1,0,1,1]
index = find(obj.storage.bitFlag=='H');
t = obj.storage.dataIndex(index)/obj.sampleFreq;
plot(t, double(obj.storage.I_Q(index,1)), 'LineStyle','none', 'Marker','.', 'Color','m')

% 标记校验帧头阶段(蓝色),该阶段的结尾一定是[1,0,0,0,1,0,1,1]
index = find(obj.storage.bitFlag=='C');
t = obj.storage.dataIndex(index)/obj.sampleFreq;
plot(t, double(obj.storage.I_Q(index,1)), 'LineStyle','none', 'Marker','.', 'Color','b')

% 标记解析星历阶段(红色)
index = find(obj.storage.bitFlag=='E');
t = obj.storage.dataIndex(index)/obj.sampleFreq;
plot(t, double(obj.storage.I_Q(index,1)), 'LineStyle','none', 'Marker','.', 'Color','r')

end