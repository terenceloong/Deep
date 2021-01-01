classdef signalSim < handle
% GPS L1 C/A信号仿真

% 信号强度说明
% 接收机复热噪声功率谱密度为-205dBW/Hz(双边带),-175dBm/Hz
% 热噪声功率谱密度计算公式:N0=kT/2, k=1.38e-23 玻尔兹曼常数
% <GPS原理与接收机设计>谢钢P244
% GPS信号落地要保证-160dBW(-130dBm),对应载噪比45dB·Hz
% 弱信号为-145dBm,对应载噪比30dB·Hz
% 正常卫星载噪比范围40~55dB·Hz,对应功率-135dBm~-120dBm
% 相关输出幅值计算公式: A/sigma = sqrt(2*T*10^(CN0/10))
% sigma=1白噪声下信号幅值计算公式: A = sqrt(10^(CN0/10)*(2/fs))
% 55dB·Hz信号幅值0.4(fs=4e6)
% 40dB·Hz信号幅值0.07(fs=4e6)
% 仿真时的信号幅值是以热噪声为参考,当有多个信号时,其他信号也相当于噪声,会使实际的载噪比低于预设值
% 实际试验时,卫星信号越多越不会出现载噪比特别大的卫星
% 对于指定积分时间所能跟踪的最弱信号要保证A/sigma=3,对应的载噪比为CN0 = 10*log10(9/(2*T))
% 1ms积分时间跟踪的最低载噪比为36.5dB·Hz
% 20ms积分时间跟踪的最低载噪比为23.5dB·Hz

% 载噪比表:第一行时间,第二行载噪比,第三行载噪比变化率
% 变化必须是线性
% 第一列的时间必须是0,第一列的变化率一般是0
% 最后一列的变化率必须是0

    properties
        PRN             %卫星编号
        CAcode          %一个周期的C/A码
        carrFactor      %载波因子
        ephe            %星历          
        message         %导航电文
        N0              %热噪声功率谱密度
        cnrMode         %载噪比模式
        cnrValue        %载噪比值
        cnrTable        %载噪比表
        ele             %高度角
        azi             %方位角
    end
    
    methods
        function obj = signalSim(PRN, sampleFreq) %构造函数
            obj.PRN = PRN;
            obj.CAcode = GPS.L1CA.codeGene(PRN);
            obj.carrFactor = -2*pi*1575.42e6;
            obj.N0 = 2 / sampleFreq; %sigma=1的复白噪声功率为2
            obj.cnrMode = 0; %默认根据高度角计算载噪比
        end
        
        function update_message(obj, t) %更新导航电文
            obj.message = [-1, -1, GPS.L1CA.messageGene(t,obj.ephe), 1, -1]; %1504个比特
        end
        
        function update_aziele(obj, t, lla) %更新方位角高度角
            % t:时间,GPS周内秒
            % lla:接收机位置,纬经高
            if ~isempty(obj.ephe) %可能有些卫星没星历
                rs = LNAV.rs_ephe(obj.ephe(10:25), t); %卫星ecef位置
                [obj.azi, obj.ele] = aziele_xyz(rs, lla); %计算方位角高度角
            else %没星历的卫星高度角置-100度
                obj.azi = 0;
                obj.ele = -100;
            end
        end
        
        function cnr = get_cnr(obj, t) %获取载噪比
            if obj.cnrMode==0 %根据高度角计算
                cnr = 35 + 20*sind(obj.ele); %最低35,最高55
            elseif obj.cnrMode==1 %常值
                cnr = obj.cnrValue;
            elseif obj.cnrMode==2 %查找载噪比表
                index = find(obj.cnrTable(1,:)<=t, 1, 'last'); %表的对应列
                cnr = obj.cnrTable(2,index) + obj.cnrTable(3,index)*(t-obj.cnrTable(1,index));
            end
        end
        
        function [sigI, sigQ] = gene_signal(obj, te0, te, tr0, tr, sampleN) %生成信号
            % te0:上次发射时间,te:当前发射时间(卫星钟,用来算码相位)
            % tr0:上次接收时间,tr:当前接收时间(接收机钟,用来算载波相位,载波相位与伪距直接相关)
            % sampleN:采样点数
            samples = (1:sampleN) / sampleN;
            SMU2S = [1;1e-3;1e-6]; %[s,ms,us]到s
            %----信号幅值
            CN0 = obj.get_cnr(tr*SMU2S); %信号载噪比
            amp = sqrt(10^(CN0/10) * obj.N0); %信号幅值
            %----生成码
            te0_us = te0(3)/1e3; %上次发射时间的微秒部分,单位:ms
            dte_us = (te-te0) * [1e3;1;1e-3]; %发射时间增量,单位:ms
            te_us_vector = te0_us + dte_us*samples; %发射时间微秒部分矢量,单位:ms
            codePhase = floor(mod(te_us_vector,1)*1023) + 1; %码相位(每1ms对应1023个码片)
            sigCode = obj.CAcode(codePhase) * amp;
            %----生成导航电文
            te0_ms = te0(1)*1e3 + te0(2); %上次发射时间的毫秒部分
            te_ms_vector = te0_ms + floor(te_us_vector); %发射时间毫秒部分矢量
            bitIndex = floor(te_ms_vector/20); %比特索引
            bitIndex = bitIndex - (floor(bitIndex(1)/1500)*1500 - 3); %将1500的整数倍剔除,补3为了实现message索引
            sigNav = obj.message(bitIndex);
            sigCode = sigCode .* sigNav;
            if bitIndex(end)>=1503 %更新导航电文
                obj.update_message(te(1));
            end
            %----生成载波
            tt0 = (tr0 - te0) * SMU2S; %上次传输时间
            tt = (tr - te) * SMU2S; %当前传输时间
            tt_vec = tt0 + (tt-tt0)*samples; %传输时间矢量
            carrPhase = tt_vec * obj.carrFactor; %载波相位
            carrPhase = carrPhase - floor(carrPhase(1)/2/pi)*2*pi; %将2pi的整数倍剔除,加速三角函数计算
            carrCos = cos(carrPhase);
            carrSin = sin(carrPhase);
            %----合成信号
            sigI = sigCode .* carrCos;
            sigQ = sigCode .* carrSin;
        end
        
    end %end methods
    
end %end classdef