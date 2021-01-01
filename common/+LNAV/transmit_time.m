function [te, tt] = transmit_time(ephe, tr, rp)
% 给定信号接收时间,反算信号发射时间和传输时间
% 发射时间为卫星钟时间,考虑相对论效应,卫星钟差,群延迟
% 传输时间为真实路径传输时间
% 迭代法,给个传输时间,算位置,再算新的传输时间,直到传输时间收敛,迭代3次就能收敛
% ephe:21参数星历
% te:发射时间[s,ms,us], tt:传输时间,s
% tr:接收时间[s,ms,us], rp:接收机ecef位置

w = 7.292115e-5;
c = 299792458;

% 计算传输时间
tr_sec = tr(1) + tr(2)/1e3 + tr(3)/1e6; %以s为单位的接收时间
tt = 0.07; %传输时间初值,70ms
while 1
    te_sec = tr_sec - tt; %计算发射时间
    [rs, dtrel] = LNAV.rs_ephe(ephe(6:21), te_sec); %卫星在发射时刻位置
    theta = w*tt;
    C = [cos(theta), -sin(theta), 0;
         sin(theta),  cos(theta), 0;
                  0,           0, 1]; %地球旋转(转置过了)
    rsp = rp - rs*C; %卫星指向天线的位置矢量
    tt0 = tt; %上次传输时间
    tt = norm(rsp) / c; %新的传输时间
    
    if abs(tt-tt0)<1e-12
        break
    end
end

% 计算卫星钟差
toc = ephe(1);
af0 = ephe(2);
af1 = ephe(3);
af2 = ephe(4);
TGD = ephe(5);
te_sec = tr_sec - tt;
dt = te_sec - toc;
dt = mod(dt+302400,604800)-302400; %限制在±302400
dtsv = af0 + af1*dt + af2*dt^2; %卫星钟差

% 计算发射时间
te = timeCarry(tr - sec2smu(tt-dtsv-dtrel+TGD));

end