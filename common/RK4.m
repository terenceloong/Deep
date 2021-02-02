function x1 = RK4(fun, x0, dt, u0, u1, u2)
% 四阶龙格库塔解微分方程
% fun:微分方程函数句柄

K1 = fun(x0, u0);
K2 = fun(x0+K1*dt/2, u1);
K3 = fun(x0+K2*dt/2, u1);
K4 = fun(x0+K3*dt, u2);
x1 = x0 + (K1+2*K2+2*K3+K4)*dt/6;

end