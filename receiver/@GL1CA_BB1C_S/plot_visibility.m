function plot_visibility(obj)
% 画卫星可见性

if all(obj.result.svnumALL(:,2)==0)
    return
end

% 时间轴
t = obj.storage.ta - obj.storage.ta(end) + obj.Tms/1000;

figure
axes
box on
hold on

% GPS部分
nGPS = 0;
labelGPS = {};
if obj.GPSflag==1
    svGPS = double(obj.storage.svselGPS);
    nGPS = size(svGPS,2); %通道数量
    for k=1:nGPS
        index1 = svGPS(:,k)~=0;
        index2 = svGPS(:,k)==0;
        svGPS(index1,k) = k;
        svGPS(index2,k) = NaN;
    end
    labelGPS = cell(1,nGPS);
    for k=1:nGPS
        labelGPS{k} = sprintf('G%d', obj.GPS.svList(k));
    end
    plot(t,svGPS, 'Color',[65,180,250]/255, 'LineWidth',10)
end

% BDS部分
nBDS = 0;
labelBDS = {};
if obj.BDSflag==1
    svBDS = double(obj.storage.svselBDS);
    nBDS = size(svBDS,2); %通道数量
    for k=1:nBDS
        index1 = svBDS(:,k)~=0;
        index2 = svBDS(:,k)==0;
        svBDS(index1,k) = k+nGPS;
        svBDS(index2,k) = NaN;
    end
    labelBDS = cell(1,nBDS);
    for k=1:nBDS
        labelBDS{k} = sprintf('C%d', obj.BDS.svList(k));
    end
    plot(t,svBDS, 'Color',[255,65,65]/255, 'LineWidth',10)
end

n = nGPS + nBDS;
set(gca, 'YLim',[0,n+1])
yticks(1:n)
yticklabels([labelGPS,labelBDS])

end