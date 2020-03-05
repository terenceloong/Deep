function P = var_phi2angle(P, att)
% att:вкл╛╫г,rad

Cnb = angle2dcm(att(1), att(2), att(3));
C = zeros(3);
C(1,1) = -Cnb(1,3)*Cnb(1,1) / (Cnb(1,1)^2+Cnb(1,2)^2);
C(1,2) = -Cnb(1,3)*Cnb(1,2) / (Cnb(1,1)^2+Cnb(1,2)^2);
C(1,3) = 1;
C(2,1) = -Cnb(1,2) / sqrt(1-Cnb(1,3)^2);
C(2,2) =  Cnb(1,1) / sqrt(1-Cnb(1,3)^2);
C(2,3) = 0;
C(3,1) = (Cnb(2,2)*Cnb(3,3)-Cnb(3,2)*Cnb(2,3)) / (Cnb(3,3)^2+Cnb(2,3)^2);
C(3,2) = (Cnb(3,1)*Cnb(2,3)-Cnb(2,1)*Cnb(3,3)) / (Cnb(3,3)^2+Cnb(2,3)^2);
C(3,3) = 0;
P = C*P*C';

end