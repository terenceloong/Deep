% 画软件接收机结果中的载噪比
% 手动设置横坐标范围

obj = nCoV;

% 颜色表
newcolors = [   0, 0.447, 0.741;
            0.850, 0.325, 0.098;
            0.929, 0.694, 0.125;
            0.494, 0.184, 0.556;
            0.466, 0.674, 0.188;
            0.301, 0.745, 0.933;
            0.635, 0.078, 0.184;
                1, 0.075, 0.651;
                1,     0,     0;
                0,     0,     1];
            
figure
colororder(newcolors) %设置颜色表
ax = axes;
box on
hold on
grid on

for k=1:obj.chN
    channel = obj.channels(k);
    if any(~isnan(channel.storage.CN0)) %只画有载噪比数据的通道
        index = isnan(channel.storage.dataIndex) | channel.storage.bitFlag~=0;
        t = channel.storage.dataIndex(index) / channel.sampleFreq;
        plot(t, channel.storage.CN0(index), 'LineWidth',1, ...
             'DisplayName',['PRN ',num2str(channel.PRN)])
    end
end

set(ax, 'FontSize',12)
set(ax, 'XLim',[20,70])
set(ax, 'YLim',[10,55])
xlabel('时间/(s)')
ylabel('载噪比/(dB·Hz)')
legend('Location','southeast')

clearvars obj