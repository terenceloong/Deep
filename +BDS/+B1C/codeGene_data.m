function code = codeGene_data(PRN)
% ���ɱ���B1C�ź����ݷ�������,���߼�
% �볤10230
% ��Weil���ĳһλ��ѭ����ȡ,����pȷ��,Weil�볤10230
% Weil����legendre��������,legendre����һ��,���ɷ�ʽ�ɲ���wȷ��,wȡֵ��Χ1~5121
% �ο����ռ��źŽӿڿ����ļ�B1C 1.0��

% w������
wlist = [2678,4802,958,859,3843,2232,124,4352,1816,1126, ...
         1860,4800,2267,424,4192,4333,2656,4148,243,1330, ...
         1593,1470,882,3202,5095,2546,1733,4795,4577,1627, ...
         3638,2553,3646,1087,1843,216,2245,726,1966,670, ...
         4130,53,4830,182,2181,2006,1080,2288,2027,271, ...
         915,497,139,3693,2054,4342,3342,2592,1007,310, ...
         4203,455,4318];

% p������
plist = [699,694,7318,2127,715,6682,7850,5495,1162,7682, ...
         6792,9973,6596,2092,19,10151,6297,5766,2359,7136, ...
         1706,2128,6827,693,9729,1620,6805,534,712,1929, ...
         5355,6139,6339,1470,6867,7851,1162,7659,1156,2672, ...
         6043,2862,180,2663,6940,1645,1582,951,6878,7701, ...
         1823,2391,2606,822,6403,239,442,6769,2560,2502, ...
         5072,7268,341];

% �������Ǳ��ѡȡw,p��ֵ
w = wlist(PRN);
p = plist(PRN);

% legendre����,-1��ʾ�߼�1,1��ʾ�߼�0
N = 10243;
L = ones(1,N); %ȫ0�߼�
for x=0:N-1 %Ϊ1�߼���ֵ
    k = mod(x*x,N);
    L(k+1) = -1;
end
L(1) = 1; %��һ��Ϊ�߼�0

% Weil������
W = zeros(1,N);
for k=0:N-1
    W(k+1) = L(k+1) * L(mod(k+w,N)+1);
end

% α�����
code = zeros(1,10230);
for n=0:10229
    code(n+1) = W(mod(n+p-1,N)+1);
end

% ��ʾͷ24����Ƭ��β24����Ƭ���˽��ƣ�
% first = code(1:24)==-1; %01����
% first = dec2bin(first)'; %�������ַ���
% first = bin2dec(first); %ʮ������
% first = dec2base(first, 8); %�˽����ַ���
% disp(first)
% last = code(end-23:end)==-1; %01����
% last = dec2bin(last)'; %�������ַ���
% last = bin2dec(last); %ʮ������
% last = dec2base(last, 8); %�˽����ַ���
% disp(last)

end