function [ephe, iono] = epheParse(bits)
% 输入完整1500比特导航电文和上一字最后两位(±1),解析GPS星历
% 如果星历为空说明星历错误

ephe = [];
iono = [];

% 所有字的校验
for k=0:49
    if GPS.L1CA.wordCheck(bits(k*30+(1:32)))==0 %只要检测到错误就返回
        return
    end
end

% 电平翻转
bits = -bits(62) * bits; %bits(62)一直为-1

% 转换成二进制01字符串
bits = dec2bin(bits>0)'; %行向量

% 记录D30,删除前两个比特
D30 = bits(2);
bits(1:2) = [];

% 子帧表
subframeTable = zeros(1,5); %如果有第几帧,对应的位置1

gpsPi = 3.1415926535898; 

for k=0:4
    subframe = bits(k*300+(1:300)); %取一个子帧
    
    % 根据校验规则对子帧中的每个字做电平翻转
    for i=1:10
        subframe(30*i+(-29:0)) = GPS.L1CA.bitsFlip(subframe(30*i+(-29:0)), D30);
        D30 = subframe(30*i);
    end
    
    subframeID = bin2dec(subframe(50:52)); %子帧ID
    
    % 校验,如果子帧号不属于1~5,或者59~60两位不为0,认为星历错误
    if ~ismember(subframeID,1:5) || subframe(59)~='0' || subframe(60)~='0'
        return
    end
    
    switch subframeID
        case 1
            TOW = (bin2dec(subframe(31:47))-1)*6;
            week = bin2dec(subframe(61:70));
            IODC = bin2dec([subframe(83:84),subframe(211:218)]);
            TGD = twosComp2dec(subframe(197:204)) * 2^(-31);
            toc = bin2dec(subframe(219:234)) * 2^4;
            af2 = twosComp2dec(subframe(241:248)) * 2^(-55);
            af1 = twosComp2dec(subframe(249:264)) * 2^(-43);
            af0 = twosComp2dec(subframe(271:292)) * 2^(-31);
            subframeTable(1) = 1;
        case 2
            IODE = bin2dec(subframe(61:68));
            Crs = twosComp2dec(subframe(69:84)) * 2^(-5);
            dn = twosComp2dec(subframe(91:106)) * 2^(-43) * gpsPi;
            M0 = twosComp2dec([subframe(107:114),subframe(121:144)]) * 2^(-31) * gpsPi;
            Cuc = twosComp2dec(subframe(151:166)) * 2^(-29);
            e = bin2dec([subframe(167:174),subframe(181:204)]) * 2^(-33);
            Cus = twosComp2dec(subframe(211:226)) * 2^(-29);
            sqa = bin2dec([subframe(227:234),subframe(241:264)]) * 2^(-19);
            toe = bin2dec(subframe(271:286)) * 2^4;
            subframeTable(2) = 1;
        case 3
            Cic = twosComp2dec(subframe(61:76)) * 2^(-29);
            Omega0 = twosComp2dec([subframe(77:84),subframe(91:114)]) * 2^(-31) * gpsPi;
            Cis = twosComp2dec(subframe(121:136)) * 2^(-29);
            i0 = twosComp2dec([subframe(137:144),subframe(151:174)]) * 2^(-31) * gpsPi;
            Crc = twosComp2dec(subframe(181:196)) * 2^(-5);
            omega = twosComp2dec([subframe(197:204),subframe(211:234)]) * 2^(-31) * gpsPi;
            Omega_dot = twosComp2dec(subframe(241:264)) * 2^(-43) * gpsPi;
            i_dot = twosComp2dec(subframe(279:292)) * 2^(-43) * gpsPi;
            subframeTable(3) = 1;
        case 4
            pageID = bin2dec(subframe(63:68));
%             disp([4,pageID])
            if pageID==56 %page 18
                alpha0 = twosComp2dec(subframe(69:76)) * 2^(-30);
                alpha1 = twosComp2dec(subframe(77:84)) * 2^(-27);
                alpha2 = twosComp2dec(subframe(91:98)) * 2^(-24);
                alpha3 = twosComp2dec(subframe(99:106)) * 2^(-24);
                beta0 = twosComp2dec(subframe(107:114)) * 2^(11);
                beta1 = twosComp2dec(subframe(121:128)) * 2^(14);
                beta2 = twosComp2dec(subframe(129:136)) * 2^(16);
                beta3 = twosComp2dec(subframe(137:144)) * 2^(16);
                iono = [alpha0,alpha1,alpha2,alpha3,beta0,beta1,beta2,beta3];
            end
            subframeTable(4) = 1;
        case 5
%             pageID = bin2dec(subframe(63:68));
%             disp([5,pageID])
            subframeTable(5) = 1;
    end
end

% 如果没有所有子帧,说明星历错误
if sum(subframeTable)~=5
	return
end

ephe = zeros(1,25);
ephe(1)  = week;
ephe(2)  = TOW;
ephe(3)  = IODC;
ephe(4)  = IODE;
ephe(5)  = toc;
ephe(6)  = af0;
ephe(7)  = af1;
ephe(8)  = af2;
ephe(9)  = TGD;
ephe(10) = toe;
ephe(11) = sqa;
ephe(12) = e;
ephe(13) = dn;
ephe(14) = M0;
ephe(15) = omega;
ephe(16) = Omega0;
ephe(17) = Omega_dot;
ephe(18) = i0;
ephe(19) = i_dot;
ephe(20) = Cus;
ephe(21) = Cuc;
ephe(22) = Crs;
ephe(23) = Crc;
ephe(24) = Cis;
ephe(25) = Cic;

end