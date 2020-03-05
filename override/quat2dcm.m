function dcm = quat2dcm(q)
% 四元数转化为姿态阵
% q为行向量,假定已经做完归一化

q1 = q(1);
q2 = q(2);
q3 = q(3);
q4 = q(4);

dcm = zeros(3);
dcm(1,1) = q1*q1 + q2*q2 - q3*q3 - q4*q4;
dcm(1,2) = 2 * (q2*q3 + q1*q4);
dcm(1,3) = 2 * (q2*q4 - q1*q3);
dcm(2,1) = 2 * (q2*q3 - q1*q4);
dcm(2,2) = q1*q1 - q2*q2 + q3*q3 - q4*q4;
dcm(2,3) = 2 * (q3*q4 + q1*q2);
dcm(3,1) = 2 * (q2*q4 + q1*q3);
dcm(3,2) = 2 * (q3*q4 - q1*q2);
dcm(3,3) = q1*q1 - q2*q2 - q3*q3 + q4*q4;

end