function q = quatCorr(q, X)
% 使用姿态失准角修正四元数
% X为姿态失准角矢量,行向量

phi = norm(X);
if phi>1e-6
    qc = [cos(phi/2), X/phi*sin(phi/2)];
    q = quatmultiply(qc, q);
end
q = q / norm(q);

end