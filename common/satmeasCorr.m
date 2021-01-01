function rho_rhodot = satmeasCorr(tt, doppler, corr)
% 对测量的信号传播时间和多普勒进行校正,得到伪距伪距率
% tt:信号传播时间travel time,s
% dpppler:归一化多普勒,无量纲,df/f0
% corr:校正项,结构体
% rho_rhodot:[伪距,伪距率],m,m/s

c = 299792458;

tt = tt + corr.dtsv + corr.dtrel - corr.dtsagnac - corr.TGD - corr.dtiono;
rho = tt*c;

df = -doppler + corr.dfsv + corr.dfrel - corr.dfsagnac; %doppler为正,相对距离减小,所以取负号
rhodot = df*c;

rho_rhodot = [rho, rhodot];

end