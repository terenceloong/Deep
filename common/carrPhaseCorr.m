function carrPhase = carrPhaseCorr(carrPhase, corr, Fca)
% 载波相位校正,单位:周
% 电离层校正与伪距相反

carrPhase = carrPhase + (corr.dtsv + corr.dtrel - corr.dtsagnac - corr.TGD + corr.dtiono)*Fca;

end