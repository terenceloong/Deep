function ax = sv_3Dview(aziele, sys, ax)
% 在三维坐标画卫星位置,可以接收图像句柄,在原图上叠加
% aziele:卫星方位角高度角,[PRN,azi,ele],deg
% sys:卫星系统代号
% ax:三维坐标轴

PRN = aziele(:,1);
azi = aziele(:,2);
ele = aziele(:,3);

% 计算直角坐标
n = length(PRN); %卫星个数
p = zeros(n,3);
p(:,1) = cosd(ele).*cosd(90-azi); %方位角是顺时针为正,直角坐标是逆时针为正
p(:,2) = cosd(ele).*sind(90-azi);
p(:,3) = sind(ele);

% 创建地平面
if ~exist('ax','var')
    figure
    ax = axes; %直角坐标轴
    X = [-1,1;-1,1];
    Y = [1,1;-1,-1];
    Z = [0,0;0,0];
    surf(X,Y,Z, 'EdgeColor',[0.929,0.694,0.125], 'FaceColor',[0.929,0.694,0.125], 'FaceAlpha',0.4) %画地平面
    axis equal
    set(gca, 'Zlim',[-0.2,1.2])
    hold on
    text(0,1,0,'N')
    text(1,0,0,'E')
    plot3([-1,1],[0,0],[0,0], 'Color',[0.929,0.694,0.125]) %画地平面分割线
    plot3([0,0],[-1,1],[0,0], 'Color',[0.929,0.694,0.125])
    plot3(0,0,0, 'Color',[0.929,0.694,0.125], 'LineStyle','none', 'Marker','.', 'MarkerSize',25) %画原点
    rotate3d on %直接打开3D视图旋转,右键选择视角,双击恢复
end

% 卫星颜色
switch sys
    case 'G'
        color = [76,114,176]/255;
    case 'C'
        color = [196,78,82]/255;
    otherwise
        color = [0,0,0]/255;
end

% 画卫星
for k=1:n
    plot3(p(k,1),p(k,2),p(k,3), 'Color',color, 'LineStyle','none', 'Marker','.', 'MarkerSize',25) %卫星点
    plot3([0,p(k,1)],[0,p(k,2)],[0,p(k,3)], 'Color',color, 'LineWidth',0.5) %卫星点与原点的连线
    text(p(k,1),p(k,2),p(k,3),['  ',sys,num2str(PRN(k))]) %卫星编号
end

end