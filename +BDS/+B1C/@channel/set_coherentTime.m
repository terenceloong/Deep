function set_coherentTime(obj, Tms)
% ������ɻ���ʱ��

% �����ڸո�����һ�����غ���ܸı���ɻ���ʱ��
if obj.trackCnt~=0
    error('Set coherent time error!')
end

% ȷ����Ƶ����ǰ���ı����ʱ��
if obj.carrDiscFlag==0
    return
end

Ts = Tms / 1000;

obj.coherentCnt = 0;
obj.coherentN = Tms;
obj.coherentTime = Ts;

% ������������������ϵ��
obj.varCoef(3) = 9e4 / (0.072*Tms);

% �����������໷ϵ��
if obj.carrMode==2 || obj.carrMode==3
    Bn = obj.PLL2(3); %��������
    [K1, K2] = order2LoopCoefD(Bn, 0.707, Ts);
    obj.PLL2(1:2) = [K1, K2];
end

% ���������뻷ϵ��
if obj.codeMode==1
    Bn = obj.DLL2(3); %��������
    [K1, K2] = order2LoopCoefD(Bn, 0.707, Ts);
    obj.DLL2(1:2) = [K1, K2];
end

end