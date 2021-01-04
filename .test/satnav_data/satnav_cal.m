% 给定一组伪距和多普勒测量值,进行卫星导航解算
% ephe0:所有卫星星历,每行一颗卫星,5~25列为有效星历数据
% iono:8个电离层参数
% time:接收机时间,[s,ms,us]
% rho:伪距序列,32列,每列一颗卫星,无数据的为NaN
% rhodot:多普勒序列(与伪距变化率相反),32列,每列一颗卫星,无数据的为NaN

c = 299792458;
f0 = 1575.42e6;
lla = [38.04643, 114.43583, 63]; %大致位置
rp = lla2ecef(lla);
vp = [0,0,0];
% iono = NaN(1,8);

satnav = zeros(N,14); %导航结果

for k=1:N
    tr = time(k,:); %接收时间
    svList = find(~isnan(rho(k,:)));
    svN = length(svList);
    sv = zeros(svN,8);
    for m=1:svN
        PRN = svList(m);
        tt = rho(k,PRN) / c; %传输时间
        doppler = rhodot(k,PRN) / f0; %归一化多普勒
        te0 = timeCarry(tr-sec2smu(tt)); %发射时间,[s,ms,us]
        [rsvs, corr] = LNAV.rsvs_emit(ephe0(PRN,5:25), te0, rp, vp, iono, lla);
        rho_rhodot = satmeasCorr(tt, doppler, corr);
        sv(m,1:6) = rsvs;
        sv(m,7:8) = rho_rhodot;
    end
    satnav(k,:) = satnavSolve(sv, rp); %卫星导航解算
end