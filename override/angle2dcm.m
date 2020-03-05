function dcm = angle2dcm(r1, r2, r3)
% ×ËÌ¬½Ç×ª»¯Îª×ËÌ¬Õó,Ðý×ªË³Ðò'zyx'
% ×ËÌ¬½Çµ¥Î»:rad

cx = cos(r3);
cy = cos(r2);
cz = cos(r1);
sx = sin(r3);
sy = sin(r2);
sz = sin(r1);

dcm = zeros(3);
dcm(1,1) = cy*cz;
dcm(1,2) = cy*sz;
dcm(1,3) = -sy;
dcm(2,1) = sy*sx*cz - sz*cx;
dcm(2,2) = sy*sx*sz + cz*cx;
dcm(2,3) = cy*sx;
dcm(3,1) = sy*cx*cz + sz*sx;
dcm(3,2) = sy*cx*sz - cz*sx;
dcm(3,3) = cy*cx;

end