function r = quatmultiply(p, q)
% 四元数乘法,四元数为行向量

q1 = q(1);
q2 = q(2);
q3 = q(3);
q4 = q(4);

r = p * [ q1,  q2,  q3,  q4;
         -q2,  q1, -q4,  q3;
         -q3,  q4,  q1, -q2;
         -q4, -q3,  q2,  q1];

end