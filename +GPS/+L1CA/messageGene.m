function out = messageGene(t, ephe)
% 生成时间t所在帧的导航电文,1500个比特,30s
% ephe:25参数星历

TOW0 = floor(t/30)*5; %当前帧的开始时间,6s为单位

preamble = [1,-1,-1,-1,1,-1,1,1]; %帧头
gpsPi = 3.1415926535898; 

WN = dec2twosComp(mod(ephe(1),1024), 10);
IODC = dec2twosComp(ephe(3), 10);
IODE = dec2twosComp(ephe(4), 8);
toc = dec2twosComp(ephe(5)/2^4, 16);
af0 = dec2twosComp(round(ephe(6)*2^31), 22);
af1 = dec2twosComp(round(ephe(7)*2^43), 16);
af2 = dec2twosComp(round(ephe(8)*2^55), 8);
TGD = dec2twosComp(round(ephe(9)*2^31), 8);
toe = dec2twosComp(ephe(10)/2^4, 16);
sqa = dec2twosComp(round(ephe(11)*2^19), 32);
e = dec2twosComp(round(ephe(12)*2^33), 32);
dn = dec2twosComp(round(ephe(13)*2^43/gpsPi), 16);
M0 = dec2twosComp(round(ephe(14)*2^31/gpsPi), 32);
omega = dec2twosComp(round(ephe(15)*2^31/gpsPi), 32);
Omega0 = dec2twosComp(round(ephe(16)*2^31/gpsPi), 32);
Omega_dot = dec2twosComp(round(ephe(17)*2^43/gpsPi), 24);
i0 = dec2twosComp(round(ephe(18)*2^31/gpsPi), 32);
i_dot = dec2twosComp(round(ephe(19)*2^43/gpsPi), 14);
Cus = dec2twosComp(round(ephe(20)*2^29), 16);
Cuc = dec2twosComp(round(ephe(21)*2^29), 16);
Crs = dec2twosComp(round(ephe(22)*2^5), 16);
Crc = dec2twosComp(round(ephe(23)*2^5), 16);
Cis = dec2twosComp(round(ephe(24)*2^29), 16);
Cic = dec2twosComp(round(ephe(25)*2^29), 16);

out = zeros(1,1502);
out(1:2) = -1; %上一帧的最后两比特一定是0

word0 = reshape([-ones(1,12);ones(1,12)], 1, 24); %字初值,±1交错

%==第一子帧======================================================
word = word0; %----TLM
word(1:8) = preamble;
word(23:24) = -1; %保留位
putword(1);
word = word0; %----HOW
word(1:17) = dec2twosComp(TOW0+1, 17); %TOW
word(18:19) = -1; %Alert Flag, Anti-Spoof Flag
word(20:22) = [-1,-1,1]; %Subframe ID
putword(2);
word = word0; %---3
word(1:10) = WN;
word(13:16) = dec2twosComp(0, 4); %URA
word(17:22) = dec2twosComp(0, 6); %Health
word(23:24) = IODC(1:2); %2MSBs
putword(3);
word = word0; %---4
putword(4);
word = word0; %---5
putword(5);
word = word0; %---6
putword(6);
word = word0; %---7
word(17:24) = TGD;
putword(7);
word = word0; %---8
word(1:8) = IODC(3:10); %8LSBs
word(9:24) = toc;
putword(8);
word = word0; %---9
word(1:8) = af2;
word(9:24) = af1;
putword(9);
word = word0; %---10
word(1:22) = af0;
putword(10);

%==第二子帧======================================================
word = word0; %----TLM
word(1:8) = preamble;
word(23:24) = -1; %保留位
putword(11);
word = word0; %----HOW
word(1:17) = dec2twosComp(TOW0+2, 17); %TOW
word(18:19) = -1; %Alert Flag, Anti-Spoof Flag
word(20:22) = [-1,1,-1]; %Subframe ID
putword(12);
word = word0; %---3
word(1:8) = IODE;
word(9:24) = Crs;
putword(13);
word = word0; %---4
word(1:16) = dn;
word(17:24) = M0(1:8); %8MSBs
putword(14);
word = word0; %---5
word(1:24) = M0(9:32); %24LSBs
putword(15);
word = word0; %---6
word(1:16) = Cuc;
word(17:24) = e(1:8); %8MSBs
putword(16);
word = word0; %---7
word(1:24) = e(9:32); %24LSBs
putword(17);
word = word0; %---8
word(1:16) = Cus;
word(17:24) = sqa(1:8); %8MSBs
putword(18);
word = word0; %---9
word(1:24) = sqa(9:32); %24LSBs
putword(19);
word = word0; %---10
word(1:16) = toe;
word(17) = -1; %fit interval flag
putword(20);

%==第三子帧======================================================
word = word0; %----TLM
word(1:8) = preamble;
word(23:24) = -1; %保留位
putword(21);
word = word0; %----HOW
word(1:17) = dec2twosComp(TOW0+3, 17); %TOW
word(18:19) = -1; %Alert Flag, Anti-Spoof Flag
word(20:22) = [-1,1,1]; %Subframe ID
putword(22);
word = word0; %---3
word(1:16) = Cic;
word(17:24) = Omega0(1:8); %8MSBs
putword(23);
word = word0; %---4
word(1:24) = Omega0(9:32); %24LSBs
putword(24);
word = word0; %---5
word(1:16) = Cis;
word(17:24) = i0(1:8); %8MSBs
putword(25);
word = word0; %---6
word(1:24) = i0(9:32); %24LSBs
putword(26);
word = word0; %---7
word(1:16) = Crc;
word(17:24) = omega(1:8); %8MSBs
putword(27);
word = word0; %---8
word(1:24) = omega(9:32); %24LSBs
putword(28);
word = word0; %---9
word(1:24) = Omega_dot;
putword(29);
word = word0; %---10
word(1:8) = IODE;
word(9:22) = i_dot;
putword(30);

%==第四子帧======================================================
word = word0; %----TLM
word(1:8) = preamble;
word(23:24) = -1; %保留位
putword(31);
word = word0; %----HOW
word(1:17) = dec2twosComp(TOW0+4, 17); %TOW
word(18:19) = -1; %Alert Flag, Anti-Spoof Flag
word(20:22) = [1,-1,-1]; %Subframe ID
putword(32);
word = word0; %---3
word(3:8) = [-1,-1,-1,-1,-1,-1]; %SV(PAGE) ID
putword(33);
word = word0; %---4
word(3:8) = [-1,-1,-1,-1,-1,-1]; %SV(PAGE) ID
putword(34);
word = word0; %---5
word(3:8) = [-1,-1,-1,-1,-1,-1]; %SV(PAGE) ID
putword(35);
word = word0; %---6
word(3:8) = [-1,-1,-1,-1,-1,-1]; %SV(PAGE) ID
putword(36);
word = word0; %---7
word(3:8) = [-1,-1,-1,-1,-1,-1]; %SV(PAGE) ID
putword(37);
word = word0; %---8
word(3:8) = [-1,-1,-1,-1,-1,-1]; %SV(PAGE) ID
putword(38);
word = word0; %---9
word(3:8) = [-1,-1,-1,-1,-1,-1]; %SV(PAGE) ID
putword(39);
word = word0; %---10
word(3:8) = [-1,-1,-1,-1,-1,-1]; %SV(PAGE) ID
putword(40);

%==第五子帧======================================================
word = word0; %----TLM
word(1:8) = preamble;
word(23:24) = -1; %保留位
putword(41);
word = word0; %----HOW
word(1:17) = dec2twosComp(mod(TOW0+5,100800), 17); %TOW
word(18:19) = -1; %Alert Flag, Anti-Spoof Flag
word(20:22) = [1,-1,1]; %Subframe ID
putword(42);
word = word0; %---3
word(3:8) = [-1,-1,-1,-1,-1,-1]; %SV(PAGE) ID
putword(43);
word = word0; %---4
word(3:8) = [-1,-1,-1,-1,-1,-1]; %SV(PAGE) ID
putword(44);
word = word0; %---5
word(3:8) = [-1,-1,-1,-1,-1,-1]; %SV(PAGE) ID
putword(45);
word = word0; %---6
word(3:8) = [-1,-1,-1,-1,-1,-1]; %SV(PAGE) ID
putword(46);
word = word0; %---7
word(3:8) = [-1,-1,-1,-1,-1,-1]; %SV(PAGE) ID
putword(47);
word = word0; %---8
word(3:8) = [-1,-1,-1,-1,-1,-1]; %SV(PAGE) ID
putword(48);
word = word0; %---9
word(3:8) = [-1,-1,-1,-1,-1,-1]; %SV(PAGE) ID
putword(49);
word = word0; %---10
word(3:8) = [-1,-1,-1,-1,-1,-1]; %SV(PAGE) ID
putword(50);

out(1:2) = []; %删除前两个多余的比特

    function putword(N)
        % 将一个设置好的字放入导航电文中,根据D30做电平翻转,生成校验码
        % N为第几个字,1~50
        index_word = (1:32)+(N-1)*30; %字的索引,32位,前两位为前一个字的D29,D30
        index_data = index_word(3:26); %数据的索引,24位
        index_parity = index_word(27:32); %校验位的索引,6位
        index_D30_p = index_word(2); %前一个字D30的索引,1位
        out(index_data) = -out(index_D30_p) * word; %根据D30做电平翻转
        [~, out(index_parity)] = GPS.L1CA.wordCheck(out(index_word)); %生成校验码
        m = mod(N,10);
        if m==2 || m==0 %每个子帧第二个字和最后一个字的最后两位必须是0
            index_D23 = index_word(25);
            index_D24 = index_word(26);
            index_D29 = index_word(31);
            index_D30 = index_word(32);
            if out(index_D29)==1
                out(index_D24) = -out(index_D24); %修改D24
                out(index_D30) = -out(index_D30); %D30取反
            end
            if out(index_D30)==1
                out(index_D23) = -out(index_D23); %修改D23
            end
            [~, out(index_parity)] = GPS.L1CA.wordCheck(out(index_word)); %重新生成校验码
            if out(index_D29)~=-1 || out(index_D30)~=-1
                error('Parity generation fail!')
            end
        end
    end

end