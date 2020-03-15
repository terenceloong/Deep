%% ���ٷ���
% �ź�Ϊ�ȼ���
% һ���˲���alpha-beta�˲���,����λ����Ƶ��
% �����˲���alpha�˲���,�ü��ٶ�ƽ��Ƶ��
% ����Ƶ��ֻ��ӳ�����˲�����״̬,�������һ���˲����Ĺ���
% �����˲�Ҫ�����,������Q
% ����һ���˲���������Ӧ�ü��Ƶ�ʹ�������,�ٸĶ����˲�����R
% ʹ�ÿ������˲�������̬�˲����Լ��ٳ�ʼ����������

clear
clc

%% ����ʱ��
T = 40; %��ʱ��
dt1 = 0.001; %һ���˲�����������
dt2 = 0.01; %�����˲�����������
n = T/dt1; %���ݵ���

%% ʵ���źŲ���
a0 = 0.6; %���ٶ�
f0 = 1;   %Ƶ��
p0 = 0;   %��λ
u = 0.05; %���ٶȲ���������׼��
v = 0.01; %��λ����������׼��

%% �����źŲ���
a = 0;  %�����ļ��ٶ�
f1 = 0; %����Ƶ��
f2 = 0; %����Ƶ��
p = 0;  %��λ

%% һ���˲���
[alpha1, beta1, Bn1, zeta1] = alpha_beta_coef(20, v, dt1);

%% �����˲���
[alpha2, Bn2] = alpha_coef(0.1, 0.06, dt2);

%% ����
output = zeros(n,3);
for k=1:n
    %----ʵ���ź�����
    p0 = p0 + f0*dt1 + 0.5*a0*dt1^2; %��λ����
    f0 = f0 + a0*dt1; %Ƶ�ʸ���
    %----�����ź�����
    p = p + f2*dt1; %��λ����,������Ƶ������,��ʱ��������ΪƵ���ǳ�ֵ
    f2 = f2 + a*dt1; %��������Ƶ��
    f1 = f1 + a*dt1; %���¹���Ƶ��
    %----һ���˲�(��ؼ�)
    df = f2 - f1; %������Ƶ�����,��Ϊ����Ƶ����f1,������Ӧ�ð�f1����,��ʵ�ʰ�f2����
    dp = p - p0 + randn*v; %��λ��,���Ƽ�����
    dp = dp - df*dt1; %�����һ��Ԥ��
    p = p - df*dt1 - alpha1*dp; %������λ
    f1 = f2 - df - beta1*dp; %����Ƶ��,f2-df=f1
    %----�����˲�
    if mod(k,dt2/dt1)==0
        df = f2 - f1; %Ƶ�����,���Ƽ�����
        f2 = f2 - alpha2*df; %��������Ƶ��
        a = a0 + randn*u; %���ٶȲ���,���±��ؼ��ٶ�
    end
    %----�洢
    output(k,1) = p - p0; %��λ�������
    output(k,2) = f1 - f0; %����Ƶ�����
    output(k,3) = f2 - f0; %����Ƶ�����
end