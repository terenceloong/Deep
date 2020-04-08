function [codeDisc, carrDisc] = getDiscOutput(obj)
% 获取定位间隔内鉴相器输出(深组合)

k0 = obj.ns0+1;
k1 = obj.ns;
codeDisc = double(obj.storage.disc(k0:k1,1))';
carrDisc = double(obj.storage.disc(k0:k1,2))';

end