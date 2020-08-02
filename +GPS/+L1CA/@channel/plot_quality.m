function plot_quality(obj)
% 画信号质量

% 带信号质量标记的I路输出
quality = obj.storage.quality; %信号质量
I = double(obj.storage.I_Q(:,1)); %I路输出
I1 = I;
I1(quality<1) = NaN; %保留强信号和弱信号
I2 = I;
I2(quality<2) = NaN; %保留强信号

PRN_str = ['GPS ',sprintf('%d',obj.PRN)];
figure('Position', screenBlock(1000,300,0.5,0.5), 'Name',PRN_str);
axes('Position', [0.05, 0.15, 0.9, 0.75]);
t = obj.storage.dataIndex/obj.sampleFreq;
plot(t, I, 'Color',[0.929,0.694,0.125]) %失锁,黄
hold on
plot(t, I1, 'Color',[0.85,0.325,0.098]) %弱信号,橘黄
plot(t, I2, 'Color',[0,0.447,0.741]) %强信号,蓝色
set(gca, 'XLim',[0,ceil(obj.Tms/1000)])

% 带信号质量标记的载波频率
quality = obj.storage.quality; %信号质量
fc = obj.storage.carrFreq; %载波频率
fc1 = fc;
fc1(quality<1) = NaN; %保留强信号和弱信号
fc2 = fc;
fc2(quality<2) = NaN; %保留强信号

PRN_str = ['GPS ',sprintf('%d',obj.PRN)];
figure('Position', screenBlock(1000,300,0.5,0.5), 'Name',PRN_str);
axes('Position', [0.05, 0.15, 0.9, 0.75]);
t = obj.storage.dataIndex/obj.sampleFreq;
plot(t, fc, 'Color',[0.929,0.694,0.125]) %失锁,黄
hold on
grid on
plot(t, fc1, 'Color',[0.85,0.325,0.098]) %弱信号,橘黄
plot(t, fc2, 'Color',[0,0.447,0.741]) %强信号,蓝色
plot(t, obj.storage.carrNco+1, 'Color',[0.5,0.5,0.5], 'LineStyle','--') %上界
plot(t, obj.storage.carrNco-1, 'Color',[0.5,0.5,0.5], 'LineStyle','--') %下界
set(gca, 'XLim',[0,ceil(obj.Tms/1000)])

end