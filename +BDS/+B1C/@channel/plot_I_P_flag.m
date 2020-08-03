function plot_I_P_flag(obj)
% 画I_P图(数据分量),带比特开始标志

PRN_str = ['BDS ',sprintf('%d',obj.PRN)];
figure('Position', screenBlock(1000,300,0.5,0.5), 'Name',PRN_str);
axes('Position', [0.05, 0.15, 0.9, 0.75]);
t = obj.storage.dataIndex/obj.sampleFreq;
plot(t, double(obj.storage.I_Q(:,7)))
set(gca, 'XLim',[0,ceil(obj.Tms/1000)])
hold on

% 标记帧同步阶段(粉色)
index = find(obj.storage.bitFlag=='F');
t = obj.storage.dataIndex(index)/obj.sampleFreq;
plot(t, double(obj.storage.I_Q(index,7)), 'LineStyle','none', 'Marker','.', 'Color','m')

% 标记等待帧头阶段(蓝色)
index = find(obj.storage.bitFlag=='H');
t = obj.storage.dataIndex(index)/obj.sampleFreq;
plot(t, double(obj.storage.I_Q(index,7)), 'LineStyle','none', 'Marker','.', 'Color','b')

% 标记解析星历阶段(红色),前6个比特为卫星编号
index = find(obj.storage.bitFlag=='E');
t = obj.storage.dataIndex(index)/obj.sampleFreq;
plot(t, double(obj.storage.I_Q(index,7)), 'LineStyle','none', 'Marker','.', 'Color','r')

end