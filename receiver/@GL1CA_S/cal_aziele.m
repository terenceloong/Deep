function [azi, ele] = cal_aziele(obj)
% 计算有卫星测量的卫星方位角高度角
% azi,ele:每列一颗卫星

if isempty(obj.result.satmeasIndex) %如果没有数据,直接返回
    return
end

n = size(obj.storage.pos,1); %数据点数
svN = obj.chN; %卫星数

azi = zeros(svN,n); %每行一颗卫星
ele = zeros(svN,n);
rs = zeros(svN,3); %存每颗卫星的位置

% 计算所有卫星方位角高度角
for k=1:n
    for i=1:svN
        rs(i,:) = obj.storage.satmeas{i}(k,1:3);
    end
    [azi(:,k), ele(:,k)] = aziele_xyz(rs, obj.storage.pos(k,:));
end
azi = azi'; %转化成每列一颗卫星
ele = ele';

% 删除无数据的列
azi = azi(:,obj.result.satmeasIndex);
ele = ele(:,obj.result.satmeasIndex);

% 画图
labels = obj.result.satmeasPRN; %卫星编号字符串
if nargout==0
    figure('Name','aziele')
    subplot(2,1,1) %画方位角
    plot(azi, 'LineWidth',1.5)
    set(gca, 'YLim',[0,360])
    legend(labels)
    grid on
    title('azimuth')
    subplot(2,1,2) %画高度角
    plot(ele, 'LineWidth',1.5)
    set(gca, 'YLim',[5,90])
    legend(labels)
    grid on
    title('elevation')
end

end