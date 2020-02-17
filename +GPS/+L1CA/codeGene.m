function code = codeGene(PRN)
% 生成GPS L1 C/A码,±1序列,行向量

if ~ismember(PRN, 1:32)
    error('PRN error!')
end

S = [2,  6;
     3,  7;
     4,  8;
     5,  9;
     1,  9;
     2, 10;
     1,  8;
     2,  9;
     3, 10;
     2,  3;
     3,  4;
     5,  6;
     6,  7;
     7,  8;
     8,  9;
     9, 10;
     1,  4;
     2,  5;
     3,  6;
     4,  7;
     5,  8;
     6,  9;
     1,  3;
     4,  6;
     5,  7;
     6,  8;
     7,  9;
     8, 10;
     1,  6;
     2,  7;
     3,  8;
     4,  9];
s1 = S(PRN,1);
s2 = S(PRN,2);

%% Method 1
% code = false(1,1023);
% 
% G1 = true(1,10);
% G2 = true(1,10);
% 
% for k=1:1023
%     code(k) = xor(G1(10),xor(G2(s1),G2(s2)));
%     G1 = [xor(G1(3),G1(10)), G1(1:9)];
%     G2 = [xor(xor(xor(xor(xor(G2(2),G2(3)),G2(6)),G2(8)),G2(9)),G2(10)), G2(1:9)];
% end
% 
% code = (double(code)-0.5)*2;

%% Method 2
% 1 is 0, -1 is 1
% 这么定义可以用乘法代替异或运算,反着定义使得(-1*-1=1,1异或1=0)
code = zeros(1,1023);

G1 = -ones(1,10);
G2 = -ones(1,10);

for k=1:1023
    code(k) = G1(10)*G2(s1)*G2(s2);
    G1 = [G1(3)*G1(10), G1(1:9)];
    G2 = [G2(2)*G2(3)*G2(6)*G2(8)*G2(9)*G2(10), G2(1:9)];
end

code = -code;

end