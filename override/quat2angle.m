function [r1, r2, r3] = quat2angle(q)
% 四元数转化为姿态角
% 姿态角单位:rad

q1 = q(1);
q2 = q(2);
q3 = q(3);
q4 = q(4);

C13 = 2 * (q2*q4 - q1*q3);
if C13>=1
    C21 = 2 * (q2*q3 - q1*q4);
    C22 = q1*q1 - q2*q2 + q3*q3 - q4*q4;
    r1 = atan2(-C21, C22);
    r2 = -pi/2;
    r3 = 0;
elseif C13<=-1
    C21 = 2 * (q2*q3 - q1*q4);
    C22 = q1*q1 - q2*q2 + q3*q3 - q4*q4;
    r1 = atan2(-C21, C22);
    r2 = pi/2;
    r3 = 0;
else
    C11 = q1*q1 + q2*q2 - q3*q3 - q4*q4;
    C12 = 2 * (q2*q3 + q1*q4);
    C23 = 2 * (q3*q4 + q1*q2);
    C33 = q1*q1 - q2*q2 - q3*q3 + q4*q4;
    r1 = atan2(C12, C11);
    r2 = asin(-C13);
    r3 = atan2(C23, C33);
end

end