function q = dcm2quat(dcm)
% 姿态阵转化为四元数

q = [0,0,0,0];
q(1) = 0.5 * sqrt(1 + dcm(1,1) + dcm(2,2) + dcm(3,3));
q(2) = 0.25 * (dcm(2,3) - dcm(3,2)) / q(1);
q(3) = 0.25 * (dcm(3,1) - dcm(1,3)) / q(1);
q(4) = 0.25 * (dcm(1,2) - dcm(2,1)) / q(1);

end