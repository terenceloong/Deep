function plot_sv_3d(obj)
% 在三维直角坐标画跟踪到的卫星
% obj:接收机对象

% 提取方位角高度角
index = obj.result.trackedIndex; %跟踪到的卫星通道索引
n = length(index); %跟踪到的卫星个数
aziele = zeros(n,3); %[PRN,azi,ele],deg
for k=1:n
    PRN = obj.channels(index(k)).PRN; %卫星编号
    aziele(k,:) = obj.aziele(obj.aziele(:,1)==PRN,:);
end

% 画图
sv_3Dview(aziele, 'G');

end