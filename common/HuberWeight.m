function y = HuberWeight(x, gamma)

y = ones(size(x));
x = abs(x);
index = x>gamma;
y(index) = gamma ./ x(index);

end