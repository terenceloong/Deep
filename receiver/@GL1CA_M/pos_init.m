function pos_init(obj)
% ��ʼ����λ

% ��ȡ���ǲ�����Ϣ
[satpv, satmeas] = obj.get_satmeas;

% ���ǵ�������(ֻ������1)
svIndex = ~isnan(satmeas{1}(:,1)); %ѡ��
sv = [satpv, satmeas{1}(:,1:2)];
satnav = satnavSolve(sv(svIndex,:), obj.rp);
dtr = satnav(13); %���ջ��Ӳ�,s

% ���½��ջ�λ���ٶ�
if ~isnan(satnav(1))
    obj.pos = satnav(1:3);
    obj.rp  = satnav(4:6);
    obj.vel = satnav(7:9);
    obj.vp  = satnav(10:12);
    obj.geogInfo = geogInfo_cal(obj.pos, obj.vel);
end

% ���ջ�ʱ�ӳ�ʼ��
if ~isnan(dtr)
    if abs(dtr)>0.1e-3 %�Ӳ����0.1ms,�������ջ�ʱ��
        obj.ta = obj.ta - sec2smu(dtr);
        obj.ta = timeCarry(obj.ta);
        obj.tp(1) = obj.ta(1); %�����´ζ�λʱ��
        obj.tp(2) = ceil(obj.ta(2)/obj.dtpos) * obj.dtpos;
        obj.tp = timeCarry(obj.tp);
    else %�Ӳ�С��0.1ms,��ʼ������
%         obj.deltaFreq = obj.deltaFreq + satnav(14); %����Ƶ��
        obj.state = 1;
    end
end

% �����´ζ�λʱ��
obj.tp = timeCarry(obj.tp + [0,obj.dtpos,0]);

end