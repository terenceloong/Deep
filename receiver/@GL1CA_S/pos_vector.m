function pos_vector(obj)
% ��ʸ�����ٶ�λ

% ����
Lca = 0.190293672798365; %�ز�����,m (299792458/1575.42e6)
Lco = 293.0522561094819; %�볤,m (299792458/1.023e6)

% ��ȡ���ǲ�����Ϣ
satmeas = obj.get_satmeas;

% �߶Ƚ���������
[~, ele] = aziele_xyz(satmeas(:,1:3), obj.pos); %���Ǹ߶Ƚ�
eleError = 5*(1-1./(1+exp(-((ele-30)/5))));

% ��ȡͨ����Ϣ
chN = obj.chN;
CN0 = zeros(chN,1); %�����
codeDisc = zeros(chN,1); %��λ�����������������ƽ��ֵ,m
R_rho = zeros(chN,1); %α�������������,m^2
R_rhodot = zeros(chN,1); %α���ʲ�����������,(m/s)^2
for k=1:chN
    channel = obj.channels(k);
    if channel.state==3
        n = channel.codeDiscBuffPtr; %����������������ݸ���
        if n>0 %��λ�����������������
            CN0(k) = channel.CN0;
            codeDisc(k) = sum(channel.codeDiscBuff(1:n))/n * Lco;
            R_rho(k) = (sqrt(channel.varValue(3)/n)+eleError(k))^2;
            R_rhodot(k) = channel.varValue(2);
        end
    end
end
sv = [satmeas, R_rho, R_rhodot];
sv(:,7) = sv(:,7) - codeDisc; %����������������α��,�����볬ǰ,α��ƫ��,�������Ϊ��,�����Ǽ�

% ���ǵ�������
svIndex = CN0>=37; %ѡ��
satnav = satnavSolveWeighted(sv(svIndex,:), obj.rp);

% �����˲�
indexP = CN0>=33; %ʹ��α�������
indexV = CN0>=37; %ʹ��α���ʵ�����(������ֵʱ,�ز����ٴ�����ֵҲҪ��)
[innP, innV] = obj.navFilter.run(sv, indexP, indexV);

% ����ecefϵ�¼��ٶ�
Cen = dcmecef2ned(obj.navFilter.pos(1), obj.navFilter.pos(2));
fn = obj.navFilter.acc; %����ϵ�¼��ٶ�
fe = fn*Cen; %ecefϵ�¼��ٶ�

% ���½��ջ�λ���ٶ�
obj.pos = obj.navFilter.pos;
obj.vel = obj.navFilter.vel;
obj.rp = obj.navFilter.rp;
obj.vp = obj.navFilter.vp;
obj.geogInfo = geogInfo_cal(obj.pos, obj.vel);

[rho0, rhodot0, rspu] = rho_rhodot_cal_ecef(satmeas(:,1:3), satmeas(:,4:6), ...
                        obj.rp, obj.vp); %������Ծ��������ٶ�
acclos0 = rspu*fe'; %������ջ��˶��������Լ��ٶ�

% ͨ������
Cdf = 1 + obj.deltaFreq; %����Ƶ�ʵ���ʵƵ�ʵ�ϵ��
dtr_code = obj.navFilter.dtr * 1.023e6; %�Ӳ��Ӧ������λ
dtv_carr = obj.navFilter.dtv * 1575.42e6; %��Ƶ���Ӧ���ز�Ƶ��
if obj.vectorMode==3 %������λ���ز�����Ƶ��
    for k=1:chN
        channel = obj.channels(k);
        if channel.state==3
            channel.codeDiscBuffPtr = 0;
            %----����λ����
            dcodePhase = (rho0(k)-satmeas(k,7))/Lco + dtr_code; %����λ������
            channel.remCodePhase = channel.remCodePhase - dcodePhase;
            %----�ز�����Ƶ������
            dcarrFreq = (rhodot0(k)-satmeas(k,8))/Lca + dtv_carr; %��Թ���Ƶ�ʵ�������
            channel.carrNco = channel.carrFreq - dcarrFreq/Cdf;
            %----���ջ��˶�������ز�Ƶ�ʱ仯��
            channel.carrAccE = -acclos0(k)/Lca / Cdf; %�����ز����ٶȹ���ֵ,�����ز����ٶ�����ֵcarrAccR
        end
    end
else
    error('vectorMode error!')
end

% �¸��ٵ�ͨ���л�ʸ�����ٻ�·
obj.channel_vector;

% ���ջ�ʱ������
obj.deltaFreq = obj.deltaFreq + obj.navFilter.dtv;
obj.navFilter.dtv = 0;
obj.ta = obj.ta - sec2smu(obj.navFilter.dtr);
obj.navFilter.dtr = 0;

% ���ݴ洢
obj.ns = obj.ns+1; %ָ��ǰ�洢��
m = obj.ns;
obj.storage.ta(m) = obj.tp * [1;1e-3;1e-6]; %��λʱ��,s
obj.storage.df(m) = obj.deltaFreq;
obj.storage.satmeas(:,:,m) = sv;
obj.storage.satnav(m,:) = satnav([1,2,3,7,8,9,13,14]);
obj.storage.svsel(m,:) = indexP + indexV;
obj.storage.pos(m,:) = obj.pos;
obj.storage.vel(m,:) = obj.vel;
P = obj.navFilter.P;
obj.storage.P(m,1:size(P,1)) = sqrt(diag(P));
obj.storage.others(m,8) = obj.navFilter.dtr;
obj.storage.others(m,9) = obj.navFilter.dtv;
obj.storage.others(m,10:12) = fn;
obj.storage.innP(m,:) = innP;
obj.storage.innV(m,:) = innV;
c = 299792458;
obj.storage.resP(m,:) = rho0 - sv(:,7) + obj.navFilter.dtr*c;
obj.storage.resV(m,:) = rhodot0 - sv(:,8) + obj.navFilter.dtv*c;

% �����´ζ�λʱ��
obj.tp = timeCarry(obj.tp + [0,obj.dtpos,0]);

end