%% ���Լ����˲���

clear
clc

%% ����ʱ��
T = 100;
dt = 0.01;
n = T/dt;

%% ʵ���źŲ���
a0 = 0.6; %���ٶ�
f0 = 1;   %Ƶ��
p0 = 0;   %��λ
v = 0.01; %��λ����������׼��

%% �����źŲ���
a = 0;  %���ٶ�
f1 = 0; %һ���˲�Ƶ��
f2 = 0; %�����˲�Ƶ��
p = 0;  %��λ

%% һ���˲���
Phi1 = [1,dt;0,1];
P1 = diag([1,1])^2;
Q1 = diag([0,1])^2 * dt^2; %����w
R1 = v^2;
H1 = [1,0];

%% �����˲���
Phi2 = [1,dt;0,1];
P2 = diag([1,1])^2;
Q2 = diag([0,0.01])^2 * dt^2;
R2 = 0.02^2;
H2 = [1,0];

%% ����
output = zeros(n,4);
X1 = [0;0];
for k=1:n
    %----ʵ���ź�����
    p0 = p0 + f0*dt + 0.5*a0*dt^2; %��λ����
    f0 = f0 + a0*dt; %Ƶ�ʸ���
    %----�����ź�����
    p = p + f1*dt; %��λ����
%     f1 = f1 + a*dt; %һ���˲�Ƶ�ʸ���,������乹���໥����,���پ���������
    f2 = f2 + a*dt; %�����˲�Ƶ�ʸ���
    %----һ���˲�
    Z = p - p0 + randn*v; %��λ������
    X1 = Phi1*X1;
    P1 = Phi1*P1*Phi1' + Q1;
    K = P1*H1' / (H1*P1*H1'+R1);
    X1 = X1 + K*(Z-H1*X1);
    P1 = (eye(2)-K*H1)*P1;
    P1 = (P1+P1')/2;
    p = p - X1(1); %��λ����
    f1 = f1 - X1(2); %Ƶ������
    X1 = [0;0];
    output(k,2) = f1 - f0; %һ���˲�Ƶ�����
    %----�����˲�
    Z = f2 - f1; %Ƶ���������
    P2 = Phi2*P2*Phi2' + Q2;
    K = P2*H2' / (H2*P2*H2'+R2);
    X2 = K*Z;
    P2 = (eye(2)-K*H2)*P2;
    P2 = (P2+P2')/2;
    f2 = f2 - X2(1); %Ƶ������
    a = a - X2(2); %���ٶ�����
    %----�����˲���һ���˲�Ƶ�ʸ�ֵ,�ⲻ���˲��������κ�Ӱ��
    X1(2) = f2 - f1; %��ؼ���һ��,����ֱ�Ӹ�ֵ,Ҫ��¼���,ȡ�����,�����������
    f1 = f2;
    %----�洢
    output(k,1) = p - p0; %��λ���
    output(k,3) = f2 - f0; %�����˲�Ƶ�����
    output(k,4) = a - a0; %���ٶ����
end