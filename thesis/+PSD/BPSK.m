% BPSK的功率谱密度

x = -20:0.01:20;
n = length(x);
y = zeros(1,n);
for k=1:n
    y(k) = G1(x(k))*G1(-x(k));
end
% y = abs(y);

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
y = 1/(1i*pi2*f) * (1 - exp(-1i*pi2*f));
end