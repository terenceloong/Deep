% BOC(6,1)自相关函数(仿真信号算的)

code1 = BDS.B1C.codeGene_pilot(1);
code2 = -code1;
code = reshape([code1;code2;code1;code2;code1;code2;code1;code2;code1;code2;code1;code2],1,[]);
c = xcorr(code);