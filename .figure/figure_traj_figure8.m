% 8字型轨迹画图,画完后调整一下视角

x0 = lla2ecef(traj(1,7:9));
h0 = traj(1,9);
pos = traj(:,1:3) - ones(size(traj,1),1)*x0;
Cen = dcmecef2ned(traj(1,7),traj(1,8));
pos = pos*Cen';
pos(:,3) = -pos(:,3);

figure
plot3(pos(:,1),pos(:,2),pos(:,3)+h0, 'LineWidth',2)
hold on
grid on
axis equal
stem3(pos(1:200:end,1),pos(1:200:end,2),pos(1:200:end,3)+h0, 'Marker','.', 'Color',[0,0.4470,0.7410])
plot3(0,0,h0, 'Marker','.', 'MarkerSize',20, 'Color',[0.8500,0.3250,0.0980])
ax = gca;
ax.YDir = 'reverse';
xlabel('北向/(m)')
ylabel('东向/(m)')
zlabel('天向/(m)')