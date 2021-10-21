% 不同权函数的图

x = -6:0.05:6;
figure
plot(x, Huber(x,1.345), 'LineWidth',1.5)
hold on
grid on
plot(x, MCC(x,2), 'LineWidth',1.5)
plot(x, DCS(x,2.35), 'LineWidth',1.5)
plot(x, IGG(x,1.5,2.5), 'LineWidth',1.5)
set(gca, 'FontSize',12)
set(gca, 'Ylim',[0,1.1])
% set(gca, 'XTick', -5:5)
legend('Huber','MCC','DCS','IGG')
xlabel('\xi')
ylabel('\psi(\xi)')

function y = Huber(x, gamma)
    y = ones(size(x));
    x = abs(x);
    index = x>gamma;
    y(index) = gamma ./ x(index);
end

% maximum correntropy criterion
function y = MCC(x, sigma)
    y = exp(-x.^2/2/sigma^2);
end

% dynamic covariance scaling
function y = DCS(x, theta)
    y = ones(size(x));
    x = abs(x);
    index = x>sqrt(theta);
    y(index) = 4*theta^2 ./ (theta+x(index).^2).^2;
end

function y = IGG(x, k0, k1)
    y = ones(size(x));
    x = abs(x);
    index = x>k0 & x<=k1;
    y(index) = k0*(k1-x(index)).^2 ./ ((k1-k0)^2*x(index));
    index = x>k1;
    y(index) = 0;
end