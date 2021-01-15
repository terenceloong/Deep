function adjust_coherentTime(obj, policy)
% 调整相干积分时间
% policy:调整策略

% 策略1,根据载噪比调整
% 小于30dB·Hz使用20ms积分时间
% 30~37dB·Hz使用5ms积分时间
% 大于37dB·Hz使用1ms积分时间
if policy==1
    if obj.CN0<30
        if obj.coherentN~=20
            obj.set_coherentTime(20);
        end
    elseif obj.CN0<37
        if obj.coherentN~=5
            obj.set_coherentTime(5);
        end
    else
        if obj.coherentN~=1
            obj.set_coherentTime(1);
        end
    end
    return
end

% 策略2,只在深组合时调整
if policy==2
    if obj.state==3
        if obj.CN0<37
            if obj.coherentN~=4
                obj.set_coherentTime(4);
            end
        else
            if obj.coherentN~=1
                obj.set_coherentTime(1);
            end
        end
    end
    return
end

end