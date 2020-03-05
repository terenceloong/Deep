function q = angle2quat(r1, r2, r3)
% 姿态角转化为四元数,旋转顺序'zyx'
% 姿态角单位:rad

cx = cos(r3/2);
cy = cos(r2/2);
cz = cos(r1/2);
sx = sin(r3/2);
sy = sin(r2/2);
sz = sin(r1/2);

q = [0,0,0,0];
q(1) = cz*cy*cx + sz*sy*sx;
q(2) = cz*cy*sx - sz*sy*cx;
q(3) = cz*sy*cx + sz*cy*sx;
q(4) = sz*cy*cx - cz*sy*sx;

end