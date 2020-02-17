function E = kepler(M, e)
% 迭代求解开普勒轨道方程

E = M;
Ei = E - (E-e*sin(E)-M)/(1-e*cos(E));
while abs(Ei-E) > 1e-12
    E = Ei;
    Ei = E - (E-e*sin(E)-M)/(1-e*cos(E));
end
    
end