% 画所有卫星的载噪比

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

figure('Name','载噪比')
colororder(newcolors) %设置颜色表
ax = axes;
ax.Box = 'on';
hold on
grid on

for k=1:nCoV.chN
    channel = nCoV.channels(k);
    if any(~isnan(channel.storage.CN0)) %只画有载噪比数据的通道
        index = isnan(channel.storage.dataIndex) | channel.storage.bitFlag~=0;
        t = channel.storage.dataIndex(index) / channel.sampleFreq;
        plot(t, channel.storage.CN0(index), 'LineWidth',1, ...
             'DisplayName',['PRN ',num2str(channel.PRN)])
    end
end

set(ax, 'FontSize',12)
set(ax, 'XLim',[0,ceil(nCoV.Tms/1000)])
set(ax, 'YLim',[0,60])
xlabel('时间/(s)')
ylabel('载噪比/(dB·Hz)')
legend('Location','SouthWest')