% 生成Spirent仿真器用的.umt文件

fclose('all');

% 检查是否存在轨迹数据
if ~exist('traj','var') || ~exist('trajGene_conf','var')
    error('No traj!')
end

fileID = fopen(['~temp\traj\',trajGene_conf.trajfile,'.umt'], 'w');

fprintf(fileID, 'INTERP_ACC, INTERP_ANG_RATE\r\n'); %加速度和角速度插值指令

n = size(traj,1);
dt = trajGene_conf.dt;
t = (0:n-1)'*dt;

d2r = pi/180;
for k=1:n
    fprintf(fileID, ['%.3f,MOTB,v1_m1,%.14f,%.14f,%.8f,%.8f,%.8f,%.8f,',...
                     '%.8f,%.8f,%.8f,%.8f,%.8f,%.8f,%.8f,%.8f,%.8f,',...
                     '%.8f,%.8f,%.8f,%.8f,%.8f,%.8f\r\n'],...
           t(k),traj(k,7)*d2r,traj(k,8)*d2r,traj(k,9),traj(k,10),traj(k,11),traj(k,12),...
           0,0,0,0,0,0,traj(k,4)*d2r,traj(k,5)*d2r,traj(k,6)*d2r,0,0,0,0,0,0);
end

fclose(fileID);