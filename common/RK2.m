function x1 = RK2(fun, x0, dt, u0, u1)
% 二阶龙格库塔解微分方程
% fun:微分方程函数句柄

K1 = fun(x0, u0);
K2 = fun(x0+K1*dt, u1);
x1 = x0 + (K1+K2)*dt/2;

end