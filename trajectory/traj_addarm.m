function traj = traj_addarm(traj, arm)
% 为仿真轨迹添加杆臂效应
% arm:杆臂矢量,IMU指向天线

n = size(traj,1);
d2r = pi/180;
w = 7.292115e-5; %地球自转角速度

for k=1:n
    lat = traj(k,7);
    lon = traj(k,8);
    h = traj(k,9);
    v = traj(k,10:12);
    r1 = traj(k,4)*d2r;
    r2 = traj(k,5)*d2r;
    r3 = traj(k,6)*d2r;
    Cnb = angle2dcm(r1,r2,r3);
    Cbn = Cnb';
    Cen = dcmecef2ned(lat, lon);
    [Rm, Rn] = earthCurveRadius(lat);
    wien = [w*cosd(lat), 0, -w*sind(lat)];
    wenn = [v(2)/(Rn+h), -v(1)/(Rm+h), -v(2)/(Rn+h)*tand(lat)];
    wibb = traj(k,13:15)*d2r;
    wnbb = wibb - (wien+wenn)*Cbn;
    r_arm = arm*Cnb*Cen;
    v_arm = cross(wnbb,arm)*Cnb;
    traj(k,1:3) = traj(k,1:3) + r_arm;
    traj(k,7:9) = ecef2lla(traj(k,1:3));
    traj(k,10:12) = traj(k,10:12) + v_arm;
end

traj(:,10:12) = round(traj(:,10:12),14); %速度尾数截断

end