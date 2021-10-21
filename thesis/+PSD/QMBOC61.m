% QMBOC(6,1,4/33)的功率谱密度

x = -20:0.01:20;
n = length(x);
y = zeros(1,n);
for k=1:n
    y(k) = (29/33) * (G1(x(k))*G1(-x(k)));
    y(k) = y(k) + (4/33) * (G2(x(k))*G2(-x(k)));
%     y(k) = (10/11) * (G1(x(k))*G1(-x(k)));
%     y(k) = y(k) + (1/11) * (G2(x(k))*G2(-x(k)));
end
% y = abs(y);
y((n+1)/2) = 1e-32;

figure
plot(x*1.023,10*log10(y), 'LineWidth',1.5)
grid on
ax = gca;
set(ax, 'FontSize',12)
set(ax, 'Xlim',[-20,20])
set(ax, 'Ylim',[-40,0])
xlabel('频率/(MHz)')
ylabel('功率谱密度/(dB/Hz)')

function y = G1(f)
pi2 = 2*pi;
y = 1/(1i*pi2*f) * (1 + exp(-1i*pi2*f) - 2*exp(-1i*pi*f));
end

function y = G2(f)
pi2 = 2*pi;
y = 1/(1i*pi2*f) * (exp(-1i*pi2*0/12*f)  - 2*exp(-1i*pi2*1/12*f) +...
                  2*exp(-1i*pi2*2/12*f)  - 2*exp(-1i*pi2*3/12*f) + ...
                  2*exp(-1i*pi2*4/12*f)  - 2*exp(-1i*pi2*5/12*f) + ...
                  2*exp(-1i*pi2*6/12*f)  - 2*exp(-1i*pi2*7/12*f) + ...
                  2*exp(-1i*pi2*8/12*f)  - 2*exp(-1i*pi2*9/12*f) + ...
                  2*exp(-1i*pi2*10/12*f) - 2*exp(-1i*pi2*11/12*f)+...
                    exp(-1i*pi2*12/12*f));
end