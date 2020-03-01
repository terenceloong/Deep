function cal_iono(obj)
% 计算所有卫星的电离层校正值(只画图)
% obj:接收机对象

% 如果没有电离层参数或者没有数据,直接返回
if isnan(obj.iono(1)) || isempty(obj.result.satmeasIndex)
    return
end

% 计算有卫星测量的卫星方位角高度角
[azi, ele] = cal_aziele(obj); %每列一颗卫星

% 计算电离层校正值
[n, svN] = size(azi); %n:数据点数,svN:卫星数
iono = NaN(n,svN);
lla = obj.storage.pos;
ta = obj.storage.ta;
for k=1:n
    for i=1:svN
        if ~isnan(azi(k,i))
            iono(k,i) = Klobuchar1(obj.iono, azi(k,i), ele(k,i), ...
                        lla(k,1), lla(k,2), ta(k));
        end
    end
end
iono = iono * 299792458; %单位变成m

% 画图
labels = obj.result.satmeasPRN; %卫星编号字符串
figure('Name','ionosphere')
plot(iono, 'LineWidth',1.5)
legend(labels)
grid on

end