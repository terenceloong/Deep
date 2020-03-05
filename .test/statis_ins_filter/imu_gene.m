function imu = imu_gene(cond)
% 生成静止状态的IMU数据,[deg/s, g]

n = cond.T/cond.dt; %数据点数
gyro = randn(n,3)*cond.sigma_gyro + ones(n,1)*cond.bias_gyro; %deg/s
att = cond.att/180*pi; %rad
Cnb = angle2dcm(att(1), att(2), att(3));
gb = (Cnb*[0;0;-1])'; %g,行向量
acc = ones(n,1)*gb + randn(n,3)*cond.sigma_acc/1000 + ...
      ones(n,1)*cond.bias_acc/1000; %g
imu = [gyro, acc];

end