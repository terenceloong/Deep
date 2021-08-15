% figure中曲线均方根误差统计
% 先点对应的图片,索引1是最上面的

clc
a = gca;
d = a.Children(1).YData;
ds = d(end-6666:end); %1333,6666
figure
plot(d)
rms = sqrt(sum(ds.^2)/length(ds))