function [r1, r2, r3] = dcm2angle(dcm)
% ×ËÌ¬Õó×ª»¯Îª×ËÌ¬½Ç
% ×ËÌ¬½Çµ¥Î»:rad

if dcm(1,3)>=1
    r1 = atan2(-dcm(2,1), dcm(2,2));
    r2 = -pi/2;
    r3 = 0;
elseif dcm(1,3)<=-1
	r1 = atan2(-dcm(2,1), dcm(2,2));
    r2 = pi/2;
    r3 = 0;
else
    r1 = atan2(dcm(1,2), dcm(1,1));
    r2 = asin(-dcm(1,3));
    r3 = atan2(dcm(2,3), dcm(3,3));
end

end