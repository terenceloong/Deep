% 测试递推计算均值,方差
% 递推算法长时间运行时可能由于计算误差造成精度下降

n = 100000; %计算点数
output = zeros(n,3);

% obj = mean_rec(1000);
obj = var_rec(1000);

for k=1:n
    x = 10 + randn*3;
    obj.update(x);
    output(k,1) = x;
    output(k,2) = obj.E;
    output(k,3) = sqrt(obj.D); %标准差
end

disp([obj.E, obj.D])
disp([mean(obj.buff), var(obj.buff,1)])