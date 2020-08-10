function plot_sv_3d(obj)
% 在三维直角坐标画跟踪到的卫星

if obj.GPSflag==1
    % 提取方位角高度角
    index = obj.result.GPS.trackedIndex; %跟踪到的卫星通道索引
    n = length(index); %跟踪到的卫星个数
    aziele = zeros(n,3); %[PRN,azi,ele],deg
    for k=1:n
        PRN = obj.GPS.channels(index(k)).PRN; %卫星编号
        aziele(k,:) = obj.GPS.aziele(obj.GPS.aziele(:,1)==PRN,:);
    end
    % 画图
    ax = sv_3Dview(aziele, 'G');
end

if obj.BDSflag==1
    % 提取方位角高度角
    index = obj.result.BDS.trackedIndex; %跟踪到的卫星通道索引
    n = length(index); %跟踪到的卫星个数
    aziele = zeros(n,3); %[PRN,azi,ele],deg
    for k=1:n
        PRN = obj.BDS.channels(index(k)).PRN; %卫星编号
        aziele(k,:) = obj.BDS.aziele(obj.BDS.aziele(:,1)==PRN,:);
    end
    % 画图
    if exist('ax','var')
        sv_3Dview(aziele, 'C', ax);
    else
        sv_3Dview(aziele, 'C');
    end
end

end